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

#### Deploy Networking
```bash
cd environments/dev/networking
terragrunt plan
terragrunt apply
```

#### Deploy Compute
```bash
cd ../compute
terragrunt plan
terragrunt apply
```

#### Deploy Database
```bash
cd ../database
terragrunt plan
terragrunt apply
```

#### Deploy Monitoring
```bash
cd ../monitoring
terragrunt plan
terragrunt apply
```

### 2. Verify Deployment
```bash
# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=dev"

# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev"

# Check Load Balancer
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(Tags[?Key==`Environment`].Value, `dev`)]'
```

## 🔍 Troubleshooting

### Common Issues

#### 1. State Lock Issues
```bash
# Force unlock (use with caution)
terragrunt force-unlock <lock-id>
```

#### 2. Permission Issues
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify S3 bucket permissions
aws s3 ls s3://terraform-terragrunt-state-$(aws sts get-caller-identity --query Account --output text)
```

#### 3. Module Not Found
```bash
# Verify module paths
terragrunt run-all plan
```

#### 4. Dependency Issues
```bash
# Check dependencies
terragrunt run-all plan --terragrunt-dependency-exclude-all
```

### Debug Mode
```bash
# Enable debug logging
export TERRAGRUNT_DEBUG=true
terragrunt plan
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
```

### 2. Plan All Environments
```bash
# Plan all environments
terragrunt run-all plan
```

### 3. Test Specific Environment
```bash
# Test development environment
cd environments/dev
terragrunt run-all plan
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
