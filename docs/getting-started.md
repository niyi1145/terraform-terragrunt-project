# Getting Started Guide

## 🚀 Quick Start

This guide will help you get started with the Terraform + Terragrunt multi-environment infrastructure project.

## 📋 Prerequisites

### Required Software
- **Terraform** >= 1.0
- **Terragrunt** >= 0.50
- **AWS CLI** >= 2.0
- **Git** >= 2.0

### AWS Requirements
- **AWS Account** with appropriate permissions
- **AWS CLI** configured with credentials
- **S3 bucket** for remote state storage
- **DynamoDB table** for state locking

## 🛠️ Installation

### Install Terraform
```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Windows
choco install terraform
```

### Install Terragrunt
```bash
# macOS
brew install terragrunt

# Linux
wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.50.0/terragrunt_linux_amd64
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt

# Windows
choco install terragrunt
```

### Verify Installation
```bash
terraform --version
terragrunt --version
aws --version
```

## 🔧 AWS Setup

### 1. Configure AWS CLI
```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-east-1)
- Default output format (json)

### 2. Create S3 Bucket for State
```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://terraform-terragrunt-state-$(aws sts get-caller-identity --query Account --output text)

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket terraform-terragrunt-state-$(aws sts get-caller-identity --query Account --output text) \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
aws s3api put-bucket-encryption \
    --bucket terraform-terragrunt-state-$(aws sts get-caller-identity --query Account --output text) \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'
```

### 3. Create DynamoDB Table for Locking
```bash
# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name terraform-terragrunt-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

### 4. Create EC2 Key Pair
```bash
# Create key pair for EC2 instances
aws ec2 create-key-pair \
    --key-name dev-keypair \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/dev-keypair.pem

chmod 400 ~/.ssh/dev-keypair.pem
```

## 📁 Project Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd terraform-terragrunt-project
```

### 2. Verify Project Structure
```bash
tree -d
```

Expected structure:
```
terraform-terragrunt-project/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/
│   ├── networking/
│   ├── compute/
│   ├── database/
│   └── monitoring/
├── scripts/
├── docs/
├── terragrunt.hcl
└── README.md
```

## 🚀 First Deployment

### 1. Deploy Development Environment

#### Step 1: Create AWS Resources
```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://terraform-terragrunt-state-$(aws sts get-caller-identity --query Account --output text)

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket terraform-terragrunt-state-$(aws sts get-caller-identity --query Account --output text) \
    --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket terraform-terragrunt-state-$(aws sts get-caller-identity --query Account --output text) \
    --server-side-encryption-configuration '{
        "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
    }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name terraform-terragrunt-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Create EC2 key pair
aws ec2 create-key-pair \
    --key-name dev-keypair \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/dev-keypair.pem

chmod 400 ~/.ssh/dev-keypair.pem
```

#### Step 2: Deploy Networking Infrastructure
```bash
# Navigate to networking directory
cd environments/dev/networking

# Plan the deployment
terragrunt plan

# Apply the configuration
terragrunt apply --auto-approve

# Verify outputs
terragrunt output
```

**Expected Output**: 23 resources created including:
- 1 VPC (10.0.0.0/16)
- 6 Subnets (2 public, 2 private, 2 database)
- 3 Security Groups (web, app, database)
- 1 Internet Gateway
- 5 Route Tables
- 2 VPC Endpoints (S3, DynamoDB)

#### Step 3: Verify Networking Deployment
```bash
# Check VPC status
aws ec2 describe-vpcs --region us-east-1 --vpc-ids vpc-0bfba57d9c4a06de2 \
    --query 'Vpcs[0].{VpcId:VpcId,State:State,CidrBlock:CidrBlock}' --output table

# Check subnets
aws ec2 describe-subnets --region us-east-1 \
    --filters "Name=vpc-id,Values=vpc-0bfba57d9c4a06de2" \
    --query 'Subnets[].{SubnetId:SubnetId,CidrBlock:CidrBlock,AvailabilityZone:AvailabilityZone,State:State}' \
    --output table

# Check security groups
aws ec2 describe-security-groups --region us-east-1 \
    --filters "Name=vpc-id,Values=vpc-0bfba57d9c4a06de2" \
    --query 'SecurityGroups[?GroupName!=`default`].{GroupId:GroupId,GroupName:GroupName}' \
    --output table

# Check internet gateway
aws ec2 describe-internet-gateways --region us-east-1 \
    --filters "Name=attachment.vpc-id,Values=vpc-0bfba57d9c4a06de2" \
    --query 'InternetGateways[].{InternetGatewayId:InternetGatewayId,State:Attachments[0].State}' \
    --output table

# Check VPC endpoints
aws ec2 describe-vpc-endpoints --region us-east-1 \
    --filters "Name=vpc-id,Values=vpc-0bfba57d9c4a06de2" \
    --query 'VpcEndpoints[].{VpcEndpointId:VpcEndpointId,ServiceName:ServiceName,State:State}' \
    --output table
```

#### Step 4: Deploy Compute (Next Phase)
```bash
cd ../compute
terragrunt plan
terragrunt apply
```

#### Step 5: Deploy Database (Next Phase)
```bash
cd ../database
terragrunt plan
terragrunt apply
```

#### Step 6: Deploy Monitoring (Next Phase)
```bash
cd ../monitoring
terragrunt plan
terragrunt apply
```

### 2. Complete Infrastructure Validation
```bash
# Comprehensive sanity test
echo "=== SANITY TEST: COMPREHENSIVE INFRASTRUCTURE VALIDATION ==="

# Test 1: VPC Status Check
echo "Test 1: VPC Status Check"
aws ec2 describe-vpcs --region us-east-1 --vpc-ids vpc-0bfba57d9c4a06de2 \
    --query 'Vpcs[0].{VpcId:VpcId,State:State,CidrBlock:CidrBlock}' --output table

# Test 2: Subnet Connectivity Check
echo "Test 2: Subnet Connectivity Check"
aws ec2 describe-subnets --region us-east-1 \
    --filters "Name=vpc-id,Values=vpc-0bfba57d9c4a06de2" \
    --query 'Subnets[].{SubnetId:SubnetId,CidrBlock:CidrBlock,AvailabilityZone:AvailabilityZone,State:State}' \
    --output table

# Test 3: Security Groups Validation
echo "Test 3: Security Groups Validation"
aws ec2 describe-security-groups --region us-east-1 \
    --filters "Name=vpc-id,Values=vpc-0bfba57d9c4a06de2" \
    --query 'SecurityGroups[?GroupName!=`default`].{GroupId:GroupId,GroupName:GroupName,IngressRules:length(IpPermissions),EgressRules:length(IpPermissionsEgress)}' \
    --output table

# Test 4: Route Tables Check
echo "Test 4: Route Tables Check"
aws ec2 describe-route-tables --region us-east-1 \
    --filters "Name=vpc-id,Values=vpc-0bfba57d9c4a06de2" \
    --query 'RouteTables[].{RouteTableId:RouteTableId,Main:Associations[0].Main,SubnetId:Associations[0].SubnetId}' \
    --output table

# Test 5: Internet Gateway Check
echo "Test 5: Internet Gateway Check"
aws ec2 describe-internet-gateways --region us-east-1 \
    --filters "Name=attachment.vpc-id,Values=vpc-0bfba57d9c4a06de2" \
    --query 'InternetGateways[].{InternetGatewayId:InternetGatewayId,State:Attachments[0].State}' \
    --output table

# Test 6: VPC Endpoints Check
echo "Test 6: VPC Endpoints Check"
aws ec2 describe-vpc-endpoints --region us-east-1 \
    --filters "Name=vpc-id,Values=vpc-0bfba57d9c4a06de2" \
    --query 'VpcEndpoints[].{VpcEndpointId:VpcEndpointId,ServiceName:ServiceName,State:State}' \
    --output table

echo "=== SANITY TEST COMPLETED ==="
```

## 🔍 Troubleshooting

### Common Issues and Solutions

#### 1. Terragrunt Command Not Found
**Error**: `command not found: terragrunt`

**Solution**:
```bash
# Install Terragrunt on macOS
brew install terragrunt

# Verify installation
terragrunt --version
```

#### 2. Duplicate Terraform Block Error
**Error**: `Duplicate terraform block`

**Solution**:
```bash
# Remove duplicate terraform blocks from terragrunt.hcl files
# Keep only one terraform block in root.hcl
# Remove terraform blocks from environment-specific files
```

#### 3. Unsupported Block Type Error
**Error**: `Unsupported block type error_hook`

**Solution**:
```bash
# Remove error_hook blocks from terragrunt.hcl files
# This block type is not supported in current Terragrunt version
```

#### 4. Include Configuration Not Found
**Error**: `Include configuration not found: ../../../terragrunt.hcl`

**Solution**:
```bash
# Rename terragrunt.hcl to root.hcl in project root
mv terragrunt.hcl root.hcl

# Update include paths in environment files
# Change: include "root" { path = find_in_parent_folders("terragrunt.hcl") }
# To: include "root" { path = find_in_parent_folders("root.hcl") }
```

#### 5. Invalid Expression in Outputs
**Error**: `Invalid expression` in outputs.tf

**Solution**:
```bash
# Simplify complex expressions in module outputs
# Replace complex calculations with simple values
# Example: total_estimated_cost = 0
```

#### 6. Failed to Read Variables File
**Error**: `Failed to read variables file terraform.tfvars`

**Solution**:
```bash
# Comment out extra_arguments "var_files" block in root.hcl
# This is not needed if not using .tfvars files
```

#### 7. Reference to Undeclared Resource
**Error**: `Reference to undeclared resource`

**Solution**:
```bash
# Set value to null for outputs referencing non-existent resources
# Example: value = null for resources not implemented in main.tf
```

#### 8. Dependency Configuration Error
**Error**: `Config ./terragrunt.hcl is a dependency of ./terragrunt.hcl`

**Solution**:
```bash
# Remove dependency blocks from root.hcl
# Dependencies should be managed at component level, not root level
```

#### 9. State Lock Issues
**Error**: `Error locking state`

**Solution**:
```bash
# Force unlock (use with caution)
terragrunt force-unlock <lock-id>

# Check DynamoDB table
aws dynamodb describe-table --table-name terraform-terragrunt-locks
```

#### 10. Permission Issues
**Error**: `Access Denied` or `403 Forbidden`

**Solution**:
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify S3 bucket permissions
aws s3 ls s3://terraform-terragrunt-state-$(aws sts get-caller-identity --query Account --output text)

# Check IAM permissions for S3 and DynamoDB
```

#### 11. GitHub Push Issues

##### Repository Not Found
**Error**: `Repository not found`

**Solution**:
```bash
# Create repository on GitHub.com first
# Then push the code
git remote add origin https://github.com/username/repository-name.git
git push -u origin main
```

##### Permission Denied (403)
**Error**: `Permission to username/repository.git denied`

**Solution**:
```bash
# Create Personal Access Token with repo scope
# Update remote URL with token
git remote set-url origin https://username:TOKEN@github.com/username/repository.git
```

##### Large File Size Error
**Error**: `File is 691.60 MB; this exceeds GitHub's file size limit of 100.00 MB`

**Solution**:
```bash
# Remove large files from git history
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch path/to/large/file' --prune-empty --tag-name-filter cat -- --all

# Force push cleaned history
git push origin main --force
```

#### 12. AWS Region Mismatch
**Error**: `The vpc ID 'vpc-xxx' does not exist`

**Solution**:
```bash
# Check AWS CLI region configuration
aws configure get region

# Use correct region in commands
aws ec2 describe-vpcs --region us-east-1 --vpc-ids vpc-xxx
```

### Debug Mode
```bash
# Enable debug logging
export TERRAGRUNT_DEBUG=true
terragrunt plan

# Clear Terragrunt cache
rm -rf .terragrunt-cache/

# Check Terragrunt configuration
terragrunt run-all plan --terragrunt-dependency-exclude-all
```

### Validation Commands
```bash
# Validate all configurations
terragrunt run-all validate

# Check for syntax errors
terragrunt run-all plan

# Verify module paths
terragrunt run-all plan --terragrunt-dependency-exclude-all
```

## 📊 Cost Monitoring

### 1. Enable Cost Explorer
```bash
# Enable Cost Explorer in AWS Console
# Go to AWS Cost Management > Cost Explorer
```

### 2. Set Up Budgets
```bash
# Create budget for development environment
aws budgets create-budget \
    --account-id $(aws sts get-caller-identity --query Account --output text) \
    --budget '{
        "BudgetName": "dev-environment-budget",
        "BudgetLimit": {
            "Amount": "100",
            "Unit": "USD"
        },
        "TimeUnit": "MONTHLY",
        "BudgetType": "COST",
        "CostFilters": {
            "TagKey": ["Environment"],
            "TagValue": ["dev"]
        }
    }'
```

## 🧪 Testing

### 1. Validate Configuration
```bash
# Validate all configurations
terragrunt run-all validate

# Validate specific environment
cd environments/dev/networking
terragrunt validate
```

### 2. Plan All Environments
```bash
# Plan all environments
terragrunt run-all plan

# Plan specific environment
cd environments/dev
terragrunt run-all plan
```

### 3. Test Specific Environment
```bash
# Test development environment
cd environments/dev
terragrunt run-all plan

# Test individual components
cd environments/dev/networking
terragrunt plan
```

### 4. Infrastructure Sanity Tests
```bash
# Run comprehensive sanity test
echo "=== SANITY TEST: COMPREHENSIVE INFRASTRUCTURE VALIDATION ==="

# Test 1: VPC Status Check
echo "Test 1: VPC Status Check"
aws ec2 describe-vpcs --region us-east-1 --vpc-ids vpc-0bfba57d9c4a06de2 \
    --query 'Vpcs[0].{VpcId:VpcId,State:State,CidrBlock:CidrBlock}' --output table

# Test 2: Subnet Connectivity Check
echo "Test 2: Subnet Connectivity Check"
aws ec2 describe-subnets --region us-east-1 \
    --filters "Name=vpc-id,Values=vpc-0bfba57d9c4a06de2" \
    --query 'Subnets[].{SubnetId:SubnetId,CidrBlock:CidrBlock,AvailabilityZone:AvailabilityZone,State:State}' \
    --output table

# Test 3: Security Groups Validation
echo "Test 3: Security Groups Validation"
aws ec2 describe-security-groups --region us-east-1 \
    --filters "Name=vpc-id,Values=vpc-0bfba57d9c4a06de2" \
    --query 'SecurityGroups[?GroupName!=`default`].{GroupId:GroupId,GroupName:GroupName,IngressRules:length(IpPermissions),EgressRules:length(IpPermissionsEgress)}' \
    --output table

# Test 4: Route Tables Check
echo "Test 4: Route Tables Check"
aws ec2 describe-route-tables --region us-east-1 \
    --filters "Name=vpc-id,Values=vpc-0bfba57d9c4a06de2" \
    --query 'RouteTables[].{RouteTableId:RouteTableId,Main:Associations[0].Main,SubnetId:Associations[0].SubnetId}' \
    --output table

# Test 5: Internet Gateway Check
echo "Test 5: Internet Gateway Check"
aws ec2 describe-internet-gateways --region us-east-1 \
    --filters "Name=attachment.vpc-id,Values=vpc-0bfba57d9c4a06de2" \
    --query 'InternetGateways[].{InternetGatewayId:InternetGatewayId,State:Attachments[0].State}' \
    --output table

# Test 6: VPC Endpoints Check
echo "Test 6: VPC Endpoints Check"
aws ec2 describe-vpc-endpoints --region us-east-1 \
    --filters "Name=vpc-id,Values=vpc-0bfba57d9c4a06de2" \
    --query 'VpcEndpoints[].{VpcEndpointId:VpcEndpointId,ServiceName:ServiceName,State:State}' \
    --output table

echo "=== SANITY TEST COMPLETED ==="
```

### 5. GitHub Repository Testing
```bash
# Test GitHub repository access
gh repo view niyi1145/terraform-terragrunt-project

# Test git operations
git status
git log --oneline -5

# Test remote repository
git remote -v
```

## 🔄 Next Steps

### 1. Deploy Staging Environment
```bash
cd environments/staging/networking
terragrunt apply
```

### 2. Deploy Production Environment
```bash
cd environments/prod/networking
terragrunt apply
```

### 3. Set Up CI/CD
- Configure GitHub Actions
- Set up automated testing
- Implement deployment pipelines

### 4. Monitor and Optimize
- Set up CloudWatch dashboards
- Configure cost alerts
- Implement backup strategies

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs/)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Best Practices Guide](docs/best-practices.md)

## 🆘 Support

If you encounter issues:

1. Check the [Troubleshooting Guide](docs/troubleshooting.md)
2. Review the [FAQ](docs/faq.md)
3. Open an issue in the repository
4. Contact the DevOps team

---

**Happy Infrastructure as Code! 🎉**
