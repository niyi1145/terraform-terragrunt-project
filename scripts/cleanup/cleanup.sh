#!/bin/bash

# =============================================================================
# Terraform + Terragrunt Infrastructure Cleanup Script
# =============================================================================
# This script provides comprehensive cleanup options for the infrastructure
# Author: DevOps Team
# Version: 1.0
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENVIRONMENTS=("dev" "staging" "prod")
COMPONENTS=("networking" "compute" "database" "monitoring")
AWS_REGION="us-east-1"

# Functions
print_header() {
    echo -e "${BLUE}=============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=============================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "CHECKING PREREQUISITES"
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terragrunt is installed
    if ! command -v terragrunt &> /dev/null; then
        print_error "Terragrunt is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Get AWS account ID
get_aws_account_id() {
    aws sts get-caller-identity --query Account --output text
}

# Get S3 bucket name
get_s3_bucket_name() {
    local account_id=$(get_aws_account_id)
    echo "terraform-terragrunt-state-${account_id}"
}

# Clean up specific environment
cleanup_environment() {
    local environment=$1
    local component=$2
    
    print_header "CLEANING UP ${environment^^} ${component^^}"
    
    local component_path="${PROJECT_ROOT}/environments/${environment}/${component}"
    
    if [ ! -d "$component_path" ]; then
        print_warning "Component path does not exist: $component_path"
        return 0
    fi
    
    cd "$component_path"
    
    # Check if terragrunt is initialized
    if [ ! -d ".terragrunt-cache" ]; then
        print_warning "Terragrunt not initialized for ${environment}/${component}. Skipping."
        return 0
    fi
    
    # Destroy infrastructure
    print_info "Destroying ${environment}/${component} infrastructure..."
    if terragrunt destroy --auto-approve; then
        print_success "Successfully destroyed ${environment}/${component}"
    else
        print_error "Failed to destroy ${environment}/${component}"
        return 1
    fi
}

# Clean up all components in an environment
cleanup_environment_all() {
    local environment=$1
    
    print_header "CLEANING UP ALL COMPONENTS IN ${environment^^}"
    
    # Destroy in reverse order (dependencies first)
    for component in "${COMPONENTS[@]}"; do
        cleanup_environment "$environment" "$component"
    done
}

# Clean up all environments
cleanup_all_environments() {
    print_header "CLEANING UP ALL ENVIRONMENTS"
    
    for environment in "${ENVIRONMENTS[@]}"; do
        cleanup_environment_all "$environment"
    done
}

# Clean up AWS resources manually
cleanup_aws_resources() {
    print_header "CLEANING UP AWS RESOURCES"
    
    local account_id=$(get_aws_account_id)
    local s3_bucket=$(get_s3_bucket_name)
    
    print_info "Account ID: $account_id"
    print_info "S3 Bucket: $s3_bucket"
    
    # Clean up VPCs
    print_info "Cleaning up VPCs..."
    local vpcs=$(aws ec2 describe-vpcs --region "$AWS_REGION" \
        --filters "Name=tag:Project,Values=terraform-terragrunt-infrastructure" \
        --query 'Vpcs[].VpcId' --output text)
    
    if [ -n "$vpcs" ]; then
        for vpc in $vpcs; do
            print_info "Deleting VPC: $vpc"
            # Delete VPC (this will fail if resources still exist)
            aws ec2 delete-vpc --region "$AWS_REGION" --vpc-id "$vpc" || true
        done
    fi
    
    # Clean up EC2 Key Pairs
    print_info "Cleaning up EC2 Key Pairs..."
    local key_pairs=$(aws ec2 describe-key-pairs --region "$AWS_REGION" \
        --query 'KeyPairs[?contains(KeyName, `dev-keypair`) || contains(KeyName, `staging-keypair`) || contains(KeyName, `prod-keypair`)].KeyName' \
        --output text)
    
    if [ -n "$key_pairs" ]; then
        for key_pair in $key_pairs; do
            print_info "Deleting Key Pair: $key_pair"
            aws ec2 delete-key-pair --region "$AWS_REGION" --key-name "$key_pair"
        done
    fi
    
    # Clean up S3 bucket
    print_info "Cleaning up S3 bucket: $s3_bucket"
    if aws s3 ls "s3://$s3_bucket" &> /dev/null; then
        aws s3 rm "s3://$s3_bucket" --recursive || true
        aws s3 rb "s3://$s3_bucket" || true
    fi
    
    # Clean up DynamoDB table
    print_info "Cleaning up DynamoDB table: terraform-terragrunt-locks"
    aws dynamodb delete-table --region "$AWS_REGION" --table-name terraform-terragrunt-locks || true
}

# Clean up local files
cleanup_local_files() {
    print_header "CLEANING UP LOCAL FILES"
    
    # Remove Terragrunt cache
    print_info "Removing Terragrunt cache directories..."
    find "$PROJECT_ROOT" -name ".terragrunt-cache" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # Remove Terraform state files
    print_info "Removing local Terraform state files..."
    find "$PROJECT_ROOT" -name "terraform.tfstate*" -type f -delete 2>/dev/null || true
    
    # Remove .terraform directories
    print_info "Removing .terraform directories..."
    find "$PROJECT_ROOT" -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # Remove SSH keys
    print_info "Removing SSH keys..."
    rm -f ~/.ssh/dev-keypair.pem ~/.ssh/staging-keypair.pem ~/.ssh/prod-keypair.pem 2>/dev/null || true
    
    print_success "Local files cleaned up"
}

# Show cleanup options
show_menu() {
    echo -e "${BLUE}=============================================================================${NC}"
    echo -e "${BLUE}                    CLEANUP OPTIONS${NC}"
    echo -e "${BLUE}=============================================================================${NC}"
    echo "1. Clean up specific environment/component"
    echo "2. Clean up all components in an environment"
    echo "3. Clean up all environments"
    echo "4. Clean up AWS resources manually"
    echo "5. Clean up local files only"
    echo "6. Full cleanup (all environments + AWS resources + local files)"
    echo "7. Exit"
    echo -e "${BLUE}=============================================================================${NC}"
}

# Interactive cleanup
interactive_cleanup() {
    while true; do
        show_menu
        read -p "Select an option (1-7): " choice
        
        case $choice in
            1)
                echo "Available environments: ${ENVIRONMENTS[*]}"
                read -p "Enter environment: " env
                echo "Available components: ${COMPONENTS[*]}"
                read -p "Enter component: " comp
                cleanup_environment "$env" "$comp"
                ;;
            2)
                echo "Available environments: ${ENVIRONMENTS[*]}"
                read -p "Enter environment: " env
                cleanup_environment_all "$env"
                ;;
            3)
                read -p "Are you sure you want to clean up ALL environments? (y/N): " confirm
                if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                    cleanup_all_environments
                fi
                ;;
            4)
                read -p "Are you sure you want to clean up AWS resources? (y/N): " confirm
                if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                    cleanup_aws_resources
                fi
                ;;
            5)
                cleanup_local_files
                ;;
            6)
                read -p "Are you sure you want to perform FULL cleanup? This will destroy ALL infrastructure! (y/N): " confirm
                if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                    cleanup_all_environments
                    cleanup_aws_resources
                    cleanup_local_files
                fi
                ;;
            7)
                print_success "Exiting cleanup script"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-7."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        echo ""
    done
}

# Command line arguments
if [ $# -eq 0 ]; then
    interactive_cleanup
else
    case $1 in
        "env")
            if [ $# -ne 3 ]; then
                print_error "Usage: $0 env <environment> <component>"
                exit 1
            fi
            check_prerequisites
            cleanup_environment "$2" "$3"
            ;;
        "env-all")
            if [ $# -ne 2 ]; then
                print_error "Usage: $0 env-all <environment>"
                exit 1
            fi
            check_prerequisites
            cleanup_environment_all "$2"
            ;;
        "all")
            check_prerequisites
            cleanup_all_environments
            ;;
        "aws")
            check_prerequisites
            cleanup_aws_resources
            ;;
        "local")
            cleanup_local_files
            ;;
        "full")
            check_prerequisites
            cleanup_all_environments
            cleanup_aws_resources
            cleanup_local_files
            ;;
        *)
            print_error "Invalid argument. Usage:"
            echo "  $0                    # Interactive mode"
            echo "  $0 env <env> <comp>   # Clean specific environment/component"
            echo "  $0 env-all <env>      # Clean all components in environment"
            echo "  $0 all                # Clean all environments"
            echo "  $0 aws                # Clean AWS resources"
            echo "  $0 local              # Clean local files only"
            echo "  $0 full               # Full cleanup"
            exit 1
            ;;
    esac
fi

print_success "Cleanup completed successfully!"
