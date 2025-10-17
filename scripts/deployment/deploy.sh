#!/bin/bash

# Terraform + Terragrunt Deployment Script
# This script automates the deployment of infrastructure across environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
ENVIRONMENTS=("dev" "staging" "prod")
COMPONENTS=("networking" "compute" "database" "monitoring")

# Default values
ENVIRONMENT=""
COMPONENT=""
ACTION="plan"
DRY_RUN=false
PARALLEL=false
AUTO_APPROVE=false
VERBOSE=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Terraform + Terragrunt Deployment Script

OPTIONS:
    -e, --environment ENV    Environment to deploy (dev, staging, prod, all)
    -c, --component COMP     Component to deploy (networking, compute, database, monitoring, all)
    -a, --action ACTION      Action to perform (plan, apply, destroy, validate)
    -d, --dry-run           Show what would be done without executing
    -p, --parallel          Run deployments in parallel
    -y, --auto-approve      Auto-approve deployments
    -v, --verbose           Enable verbose output
    -h, --help              Show this help message

EXAMPLES:
    $0 -e dev -c networking -a plan
    $0 -e staging -c all -a apply
    $0 -e prod -c compute -a destroy -y
    $0 -e all -c all -a validate

EOF
}

# Function to validate environment
validate_environment() {
    local env=$1
    if [[ "$env" != "all" && ! " ${ENVIRONMENTS[@]} " =~ " ${env} " ]]; then
        print_error "Invalid environment: $env"
        print_error "Valid environments: ${ENVIRONMENTS[*]}"
        exit 1
    fi
}

# Function to validate component
validate_component() {
    local comp=$1
    if [[ "$comp" != "all" && ! " ${COMPONENTS[@]} " =~ " ${comp} " ]]; then
        print_error "Invalid component: $comp"
        print_error "Valid components: ${COMPONENTS[*]}"
        exit 1
    fi
}

# Function to validate action
validate_action() {
    local action=$1
    if [[ ! " plan apply destroy validate " =~ " ${action} " ]]; then
        print_error "Invalid action: $action"
        print_error "Valid actions: plan, apply, destroy, validate"
        exit 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if terragrunt is installed
    if ! command -v terragrunt &> /dev/null; then
        print_error "Terragrunt is not installed. Please install it first."
        exit 1
    fi
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to setup environment
setup_environment() {
    local env=$1
    print_status "Setting up environment: $env"
    
    # Create S3 bucket for state if it doesn't exist
    local bucket_name="terraform-terragrunt-state-$(aws sts get-caller-identity --query Account --output text)"
    
    if ! aws s3 ls "s3://$bucket_name" &> /dev/null; then
        print_status "Creating S3 bucket for state: $bucket_name"
        aws s3 mb "s3://$bucket_name"
        aws s3api put-bucket-versioning --bucket "$bucket_name" --versioning-configuration Status=Enabled
        aws s3api put-bucket-encryption --bucket "$bucket_name" --server-side-encryption-configuration '{
            "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
        }'
        print_success "S3 bucket created: $bucket_name"
    fi
    
    # Create DynamoDB table for locking if it doesn't exist
    if ! aws dynamodb describe-table --table-name terraform-terragrunt-locks &> /dev/null; then
        print_status "Creating DynamoDB table for state locking"
        aws dynamodb create-table \
            --table-name terraform-terragrunt-locks \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
        print_success "DynamoDB table created: terraform-terragrunt-locks"
    fi
    
    print_success "Environment setup completed: $env"
}

# Function to deploy component
deploy_component() {
    local env=$1
    local comp=$2
    local action=$3
    
    local component_path="$PROJECT_ROOT/environments/$env/$comp"
    
    if [[ ! -d "$component_path" ]]; then
        print_warning "Component path does not exist: $component_path"
        return 0
    fi
    
    print_status "Deploying $comp in $env environment..."
    
    cd "$component_path"
    
    # Set environment variables
    export TERRAGRUNT_DEBUG=$VERBOSE
    
    # Execute terragrunt command
    local terragrunt_cmd="terragrunt $action"
    
    if [[ "$action" == "apply" && "$AUTO_APPROVE" == true ]]; then
        terragrunt_cmd="$terragrunt_cmd --auto-approve"
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_status "DRY RUN: Would execute: $terragrunt_cmd"
        return 0
    fi
    
    # Execute the command
    if eval "$terragrunt_cmd"; then
        print_success "Successfully deployed $comp in $env environment"
    else
        print_error "Failed to deploy $comp in $env environment"
        return 1
    fi
}

# Function to deploy environment
deploy_environment() {
    local env=$1
    local comp=$2
    local action=$3
    
    print_status "Deploying environment: $env"
    
    # Setup environment
    setup_environment "$env"
    
    # Deploy components
    if [[ "$comp" == "all" ]]; then
        for component in "${COMPONENTS[@]}"; do
            if [[ "$PARALLEL" == true ]]; then
                deploy_component "$env" "$component" "$action" &
            else
                deploy_component "$env" "$component" "$action"
            fi
        done
        
        # Wait for parallel jobs to complete
        if [[ "$PARALLEL" == true ]]; then
            wait
        fi
    else
        deploy_component "$env" "$comp" "$action"
    fi
    
    print_success "Environment deployment completed: $env"
}

# Function to deploy all environments
deploy_all_environments() {
    local comp=$1
    local action=$2
    
    print_status "Deploying all environments"
    
    for env in "${ENVIRONMENTS[@]}"; do
        if [[ "$PARALLEL" == true ]]; then
            deploy_environment "$env" "$comp" "$action" &
        else
            deploy_environment "$env" "$comp" "$action"
        fi
    done
    
    # Wait for parallel jobs to complete
    if [[ "$PARALLEL" == true ]]; then
        wait
    fi
    
    print_success "All environments deployment completed"
}

# Function to show deployment summary
show_summary() {
    print_status "Deployment Summary"
    echo "Environment: $ENVIRONMENT"
    echo "Component: $COMPONENT"
    echo "Action: $ACTION"
    echo "Dry Run: $DRY_RUN"
    echo "Parallel: $PARALLEL"
    echo "Auto Approve: $AUTO_APPROVE"
    echo "Verbose: $VERBOSE"
    echo ""
}

# Main function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -c|--component)
                COMPONENT="$2"
                shift 2
                ;;
            -a|--action)
                ACTION="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -p|--parallel)
                PARALLEL=true
                shift
                ;;
            -y|--auto-approve)
                AUTO_APPROVE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate required parameters
    if [[ -z "$ENVIRONMENT" ]]; then
        print_error "Environment is required"
        show_usage
        exit 1
    fi
    
    if [[ -z "$COMPONENT" ]]; then
        print_error "Component is required"
        show_usage
        exit 1
    fi
    
    # Validate parameters
    validate_environment "$ENVIRONMENT"
    validate_component "$COMPONENT"
    validate_action "$ACTION"
    
    # Show summary
    show_summary
    
    # Check prerequisites
    check_prerequisites
    
    # Execute deployment
    if [[ "$ENVIRONMENT" == "all" ]]; then
        deploy_all_environments "$COMPONENT" "$ACTION"
    else
        deploy_environment "$ENVIRONMENT" "$COMPONENT" "$ACTION"
    fi
    
    print_success "Deployment completed successfully!"
}

# Run main function
main "$@"
