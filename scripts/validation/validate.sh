#!/bin/bash

# =============================================================================
# Terraform + Terragrunt Infrastructure Validation Script
# =============================================================================
# This script provides comprehensive validation for the infrastructure
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

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Functions
print_header() {
    echo -e "${BLUE}=============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=============================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED_TESTS++))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED_TESTS++))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Test counter
increment_test() {
    ((TOTAL_TESTS++))
}

# Check prerequisites
check_prerequisites() {
    print_header "CHECKING PREREQUISITES"
    
    increment_test
    if command -v aws &> /dev/null; then
        print_success "AWS CLI is installed"
    else
        print_error "AWS CLI is not installed"
        return 1
    fi
    
    increment_test
    if command -v terragrunt &> /dev/null; then
        print_success "Terragrunt is installed"
    else
        print_error "Terragrunt is not installed"
        return 1
    fi
    
    increment_test
    if command -v terraform &> /dev/null; then
        print_success "Terraform is installed"
    else
        print_error "Terraform is not installed"
        return 1
    fi
    
    increment_test
    if aws sts get-caller-identity &> /dev/null; then
        print_success "AWS credentials are configured"
    else
        print_error "AWS credentials not configured"
        return 1
    fi
}

# Validate Terragrunt configuration
validate_terragrunt_config() {
    print_header "VALIDATING TERRAGRUNT CONFIGURATION"
    
    # Check root configuration
    increment_test
    if [ -f "$PROJECT_ROOT/root.hcl" ]; then
        print_success "Root configuration file exists"
    else
        print_error "Root configuration file missing"
    fi
    
    # Validate each environment
    for environment in "${ENVIRONMENTS[@]}"; do
        for component in "${COMPONENTS[@]}"; do
            local config_path="$PROJECT_ROOT/environments/$environment/$component/terragrunt.hcl"
            
            increment_test
            if [ -f "$config_path" ]; then
                print_success "Configuration exists: $environment/$component"
                
                # Validate Terragrunt syntax
                increment_test
                if terragrunt validate --terragrunt-working-dir "$PROJECT_ROOT/environments/$environment/$component" &> /dev/null; then
                    print_success "Terragrunt syntax valid: $environment/$component"
                else
                    print_error "Terragrunt syntax invalid: $environment/$component"
                fi
            else
                print_warning "Configuration missing: $environment/$component"
            fi
        done
    done
}

# Validate Terraform modules
validate_terraform_modules() {
    print_header "VALIDATING TERRAFORM MODULES"
    
    for component in "${COMPONENTS[@]}"; do
        local module_path="$PROJECT_ROOT/modules/$component"
        
        increment_test
        if [ -d "$module_path" ]; then
            print_success "Module directory exists: $component"
            
            # Check required files
            increment_test
            if [ -f "$module_path/main.tf" ]; then
                print_success "main.tf exists: $component"
            else
                print_error "main.tf missing: $component"
            fi
            
            increment_test
            if [ -f "$module_path/variables.tf" ]; then
                print_success "variables.tf exists: $component"
            else
                print_error "variables.tf missing: $component"
            fi
            
            increment_test
            if [ -f "$module_path/outputs.tf" ]; then
                print_success "outputs.tf exists: $component"
            else
                print_error "outputs.tf missing: $component"
            fi
            
            # Validate Terraform syntax
            increment_test
            if terraform validate -chdir="$module_path" &> /dev/null; then
                print_success "Terraform syntax valid: $component"
            else
                print_error "Terraform syntax invalid: $component"
            fi
        else
            print_error "Module directory missing: $component"
        fi
    done
}

# Validate AWS resources
validate_aws_resources() {
    print_header "VALIDATING AWS RESOURCES"
    
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local s3_bucket="terraform-terragrunt-state-${account_id}"
    
    # Check S3 bucket
    increment_test
    if aws s3 ls "s3://$s3_bucket" &> /dev/null; then
        print_success "S3 bucket exists: $s3_bucket"
        
        # Check versioning
        increment_test
        local versioning=$(aws s3api get-bucket-versioning --bucket "$s3_bucket" --query 'Status' --output text 2>/dev/null || echo "Disabled")
        if [ "$versioning" = "Enabled" ]; then
            print_success "S3 bucket versioning enabled"
        else
            print_warning "S3 bucket versioning not enabled"
        fi
        
        # Check encryption
        increment_test
        if aws s3api get-bucket-encryption --bucket "$s3_bucket" &> /dev/null; then
            print_success "S3 bucket encryption enabled"
        else
            print_warning "S3 bucket encryption not enabled"
        fi
    else
        print_error "S3 bucket missing: $s3_bucket"
    fi
    
    # Check DynamoDB table
    increment_test
    if aws dynamodb describe-table --region "$AWS_REGION" --table-name terraform-terragrunt-locks &> /dev/null; then
        print_success "DynamoDB table exists: terraform-terragrunt-locks"
    else
        print_error "DynamoDB table missing: terraform-terragrunt-locks"
    fi
    
    # Check EC2 Key Pairs
    increment_test
    local key_pairs=$(aws ec2 describe-key-pairs --region "$AWS_REGION" \
        --query 'KeyPairs[?contains(KeyName, `dev-keypair`) || contains(KeyName, `staging-keypair`) || contains(KeyName, `prod-keypair`)].KeyName' \
        --output text)
    
    if [ -n "$key_pairs" ]; then
        print_success "EC2 Key Pairs exist: $key_pairs"
    else
        print_warning "No EC2 Key Pairs found"
    fi
}

# Validate deployed infrastructure
validate_deployed_infrastructure() {
    print_header "VALIDATING DEPLOYED INFRASTRUCTURE"
    
    # Check VPCs
    increment_test
    local vpcs=$(aws ec2 describe-vpcs --region "$AWS_REGION" \
        --filters "Name=tag:Project,Values=terraform-terragrunt-infrastructure" \
        --query 'Vpcs[].VpcId' --output text)
    
    if [ -n "$vpcs" ]; then
        print_success "VPCs found: $vpcs"
        
        for vpc in $vpcs; do
            # Check subnets
            increment_test
            local subnets=$(aws ec2 describe-subnets --region "$AWS_REGION" \
                --filters "Name=vpc-id,Values=$vpc" \
                --query 'Subnets[].SubnetId' --output text)
            
            if [ -n "$subnets" ]; then
                print_success "Subnets found for VPC $vpc: $(echo $subnets | wc -w) subnets"
            else
                print_error "No subnets found for VPC $vpc"
            fi
            
            # Check security groups
            increment_test
            local security_groups=$(aws ec2 describe-security-groups --region "$AWS_REGION" \
                --filters "Name=vpc-id,Values=$vpc" "Name=group-name,Values=!default" \
                --query 'SecurityGroups[].GroupId' --output text)
            
            if [ -n "$security_groups" ]; then
                print_success "Security groups found for VPC $vpc: $(echo $security_groups | wc -w) groups"
            else
                print_warning "No custom security groups found for VPC $vpc"
            fi
            
            # Check internet gateway
            increment_test
            local igw=$(aws ec2 describe-internet-gateways --region "$AWS_REGION" \
                --filters "Name=attachment.vpc-id,Values=$vpc" \
                --query 'InternetGateways[].InternetGatewayId' --output text)
            
            if [ -n "$igw" ]; then
                print_success "Internet Gateway found for VPC $vpc: $igw"
            else
                print_warning "No Internet Gateway found for VPC $vpc"
            fi
            
            # Check VPC endpoints
            increment_test
            local vpc_endpoints=$(aws ec2 describe-vpc-endpoints --region "$AWS_REGION" \
                --filters "Name=vpc-id,Values=$vpc" \
                --query 'VpcEndpoints[].VpcEndpointId' --output text)
            
            if [ -n "$vpc_endpoints" ]; then
                print_success "VPC Endpoints found for VPC $vpc: $(echo $vpc_endpoints | wc -w) endpoints"
            else
                print_warning "No VPC Endpoints found for VPC $vpc"
            fi
        done
    else
        print_warning "No VPCs found with project tag"
    fi
}

# Validate network connectivity
validate_network_connectivity() {
    print_header "VALIDATING NETWORK CONNECTIVITY"
    
    local vpcs=$(aws ec2 describe-vpcs --region "$AWS_REGION" \
        --filters "Name=tag:Project,Values=terraform-terragrunt-infrastructure" \
        --query 'Vpcs[].VpcId' --output text)
    
    for vpc in $vpcs; do
        # Check route tables
        increment_test
        local route_tables=$(aws ec2 describe-route-tables --region "$AWS_REGION" \
            --filters "Name=vpc-id,Values=$vpc" \
            --query 'RouteTables[].RouteTableId' --output text)
        
        if [ -n "$route_tables" ]; then
            print_success "Route tables found for VPC $vpc: $(echo $route_tables | wc -w) tables"
        else
            print_error "No route tables found for VPC $vpc"
        fi
        
        # Check public subnets have internet gateway routes
        increment_test
        local public_subnets=$(aws ec2 describe-subnets --region "$AWS_REGION" \
            --filters "Name=vpc-id,Values=$vpc" "Name=tag:Tier,Values=Web" \
            --query 'Subnets[].SubnetId' --output text)
        
        if [ -n "$public_subnets" ]; then
            print_success "Public subnets found for VPC $vpc: $(echo $public_subnets | wc -w) subnets"
        else
            print_warning "No public subnets found for VPC $vpc"
        fi
    done
}

# Validate security configuration
validate_security_configuration() {
    print_header "VALIDATING SECURITY CONFIGURATION"
    
    local vpcs=$(aws ec2 describe-vpcs --region "$AWS_REGION" \
        --filters "Name=tag:Project,Values=terraform-terragrunt-infrastructure" \
        --query 'Vpcs[].VpcId' --output text)
    
    for vpc in $vpcs; do
        # Check security group rules
        increment_test
        local security_groups=$(aws ec2 describe-security-groups --region "$AWS_REGION" \
            --filters "Name=vpc-id,Values=$vpc" "Name=group-name,Values=!default" \
            --query 'SecurityGroups[].GroupId' --output text)
        
        for sg in $security_groups; do
            local ingress_rules=$(aws ec2 describe-security-groups --region "$AWS_REGION" \
                --group-ids "$sg" \
                --query 'SecurityGroups[0].IpPermissions | length(@)' --output text)
            
            local egress_rules=$(aws ec2 describe-security-groups --region "$AWS_REGION" \
                --group-ids "$sg" \
                --query 'SecurityGroups[0].IpPermissionsEgress | length(@)' --output text)
            
            if [ "$ingress_rules" -gt 0 ] && [ "$egress_rules" -gt 0 ]; then
                print_success "Security group $sg has proper rules (Ingress: $ingress_rules, Egress: $egress_rules)"
            else
                print_warning "Security group $sg may have missing rules"
            fi
        done
    done
}

# Validate cost optimization
validate_cost_optimization() {
    print_header "VALIDATING COST OPTIMIZATION"
    
    # Check for NAT Gateways (expensive)
    increment_test
    local nat_gateways=$(aws ec2 describe-nat-gateways --region "$AWS_REGION" \
        --filter "Name=state,Values=available" \
        --query 'NatGateways[].NatGatewayId' --output text)
    
    if [ -n "$nat_gateways" ]; then
        print_warning "NAT Gateways found (cost consideration): $nat_gateways"
    else
        print_success "No NAT Gateways found (cost optimized)"
    fi
    
    # Check for unused Elastic IPs
    increment_test
    local unused_eips=$(aws ec2 describe-addresses --region "$AWS_REGION" \
        --query 'Addresses[?AssociationId==null].AllocationId' --output text)
    
    if [ -n "$unused_eips" ]; then
        print_warning "Unused Elastic IPs found (cost consideration): $unused_eips"
    else
        print_success "No unused Elastic IPs found"
    fi
}

# Generate validation report
generate_report() {
    print_header "VALIDATION REPORT"
    
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo "Warnings: $((TOTAL_TESTS - PASSED_TESTS - FAILED_TESTS))"
    
    local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "Success Rate: $success_rate%"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        print_success "All critical validations passed!"
    else
        print_error "$FAILED_TESTS critical validations failed!"
    fi
    
    echo ""
    echo "Validation completed at: $(date)"
}

# Show validation options
show_menu() {
    echo -e "${BLUE}=============================================================================${NC}"
    echo -e "${BLUE}                    VALIDATION OPTIONS${NC}"
    echo -e "${BLUE}=============================================================================${NC}"
    echo "1. Prerequisites check"
    echo "2. Terragrunt configuration validation"
    echo "3. Terraform modules validation"
    echo "4. AWS resources validation"
    echo "5. Deployed infrastructure validation"
    echo "6. Network connectivity validation"
    echo "7. Security configuration validation"
    echo "8. Cost optimization validation"
    echo "9. Full validation (all checks)"
    echo "10. Exit"
    echo -e "${BLUE}=============================================================================${NC}"
}

# Interactive validation
interactive_validation() {
    while true; do
        show_menu
        read -p "Select an option (1-10): " choice
        
        case $choice in
            1)
                check_prerequisites
                ;;
            2)
                validate_terragrunt_config
                ;;
            3)
                validate_terraform_modules
                ;;
            4)
                validate_aws_resources
                ;;
            5)
                validate_deployed_infrastructure
                ;;
            6)
                validate_network_connectivity
                ;;
            7)
                validate_security_configuration
                ;;
            8)
                validate_cost_optimization
                ;;
            9)
                check_prerequisites
                validate_terragrunt_config
                validate_terraform_modules
                validate_aws_resources
                validate_deployed_infrastructure
                validate_network_connectivity
                validate_security_configuration
                validate_cost_optimization
                generate_report
                ;;
            10)
                print_success "Exiting validation script"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-10."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        echo ""
    done
}

# Command line arguments
if [ $# -eq 0 ]; then
    interactive_validation
else
    case $1 in
        "prereq")
            check_prerequisites
            ;;
        "config")
            validate_terragrunt_config
            ;;
        "modules")
            validate_terraform_modules
            ;;
        "aws")
            validate_aws_resources
            ;;
        "infra")
            validate_deployed_infrastructure
            ;;
        "network")
            validate_network_connectivity
            ;;
        "security")
            validate_security_configuration
            ;;
        "cost")
            validate_cost_optimization
            ;;
        "full")
            check_prerequisites
            validate_terragrunt_config
            validate_terraform_modules
            validate_aws_resources
            validate_deployed_infrastructure
            validate_network_connectivity
            validate_security_configuration
            validate_cost_optimization
            generate_report
            ;;
        *)
            print_error "Invalid argument. Usage:"
            echo "  $0                    # Interactive mode"
            echo "  $0 prereq             # Prerequisites check"
            echo "  $0 config             # Terragrunt configuration validation"
            echo "  $0 modules            # Terraform modules validation"
            echo "  $0 aws                # AWS resources validation"
            echo "  $0 infra              # Deployed infrastructure validation"
            echo "  $0 network            # Network connectivity validation"
            echo "  $0 security           # Security configuration validation"
            echo "  $0 cost               # Cost optimization validation"
            echo "  $0 full               # Full validation"
            exit 1
            ;;
    esac
fi

if [ $# -gt 0 ] && [ "$1" != "full" ]; then
    generate_report
fi
