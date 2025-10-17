# Scripts Directory

This directory contains utility scripts for managing and validating the Terraform + Terragrunt infrastructure.

## 📁 Scripts Overview

### 🧹 Cleanup Scripts

#### `cleanup/cleanup.sh`
Comprehensive cleanup script for infrastructure resources.

**Features:**
- Interactive and command-line modes
- Environment-specific cleanup
- Component-specific cleanup
- AWS resource cleanup
- Local file cleanup
- Safety confirmations for destructive operations

**Usage:**
```bash
# Interactive mode
./scripts/cleanup/cleanup.sh

# Command-line mode
./scripts/cleanup/cleanup.sh env dev networking    # Clean specific component
./scripts/cleanup/cleanup.sh env-all dev          # Clean all components in environment
./scripts/cleanup/cleanup.sh all                  # Clean all environments
./scripts/cleanup/cleanup.sh aws                  # Clean AWS resources
./scripts/cleanup/cleanup.sh local                # Clean local files only
./scripts/cleanup/cleanup.sh full                 # Full cleanup
```

### 🔍 Validation Scripts

#### `validation/validate.sh`
Comprehensive validation script for infrastructure components.

**Features:**
- Prerequisites validation
- Terragrunt configuration validation
- Terraform modules validation
- AWS resources validation
- Deployed infrastructure validation
- Network connectivity validation
- Security configuration validation
- Cost optimization validation
- Detailed reporting

**Usage:**
```bash
# Interactive mode
./scripts/validation/validate.sh

# Command-line mode
./scripts/validation/validate.sh prereq           # Prerequisites check
./scripts/validation/validate.sh config           # Terragrunt configuration validation
./scripts/validation/validate.sh modules          # Terraform modules validation
./scripts/validation/validate.sh aws              # AWS resources validation
./scripts/validation/validate.sh infra            # Deployed infrastructure validation
./scripts/validation/validate.sh network          # Network connectivity validation
./scripts/validation/validate.sh security         # Security configuration validation
./scripts/validation/validate.sh cost             # Cost optimization validation
./scripts/validation/validate.sh full             # Full validation
```

#### `quick-validation.sh`
Fast infrastructure status check for quick validation.

**Features:**
- AWS connectivity test
- VPC status check
- Subnet count validation
- Security group validation
- Internet Gateway check
- VPC endpoints validation
- S3 bucket verification
- DynamoDB table verification

**Usage:**
```bash
./scripts/quick-validation.sh
```

### 🧪 Testing Scripts

#### `test-scripts.sh`
Utility script for testing script functionality.

**Features:**
- Tests cleanup and validation scripts
- Validates AWS connectivity
- Checks tool versions
- Basic functionality verification

**Usage:**
```bash
./scripts/test-scripts.sh
```

## 🚀 Quick Start

### 1. Make Scripts Executable
```bash
chmod +x scripts/*/*.sh
chmod +x scripts/*.sh
```

### 2. Run Quick Validation
```bash
./scripts/quick-validation.sh
```

### 3. Run Full Validation
```bash
./scripts/validation/validate.sh full
```

### 4. Clean Local Files (Safe)
```bash
./scripts/cleanup/cleanup.sh local
```

## 📋 Script Features

### 🎨 User Experience
- **Color-coded output** for better readability
- **Progress indicators** for long-running operations
- **Interactive menus** for guided operations
- **Confirmation prompts** for destructive operations
- **Detailed error messages** with troubleshooting hints

### 🛡️ Safety Features
- **Confirmation prompts** for destructive operations
- **Dry-run capabilities** where applicable
- **Error handling** with graceful failures
- **Resource validation** before cleanup
- **Backup recommendations** for critical operations

### 📊 Reporting
- **Test counters** and success rates
- **Detailed validation reports**
- **Resource status summaries**
- **Cost optimization recommendations**
- **Security configuration analysis**

## 🔧 Prerequisites

### Required Tools
- **AWS CLI** >= 2.0
- **Terraform** >= 1.0
- **Terragrunt** >= 0.50
- **Bash** >= 4.0

### Required Permissions
- **AWS IAM permissions** for EC2, VPC, S3, DynamoDB
- **Read access** to project files
- **Write access** to temporary directories

## 📝 Usage Examples

### Daily Operations
```bash
# Quick infrastructure check
./scripts/quick-validation.sh

# Validate specific environment
./scripts/validation/validate.sh infra
```

### Development Workflow
```bash
# Clean local files after testing
./scripts/cleanup/cleanup.sh local

# Validate configuration changes
./scripts/validation/validate.sh config
```

### Production Operations
```bash
# Full infrastructure validation
./scripts/validation/validate.sh full

# Clean specific environment
./scripts/cleanup/cleanup.sh env-all dev
```

### Emergency Cleanup
```bash
# Full cleanup with confirmations
./scripts/cleanup/cleanup.sh full
```

## 🚨 Important Notes

### ⚠️ Cleanup Warnings
- **Full cleanup** will destroy ALL infrastructure
- **AWS resource cleanup** may incur costs
- **Always backup** important data before cleanup
- **Test in development** before production cleanup

### 🔒 Security Considerations
- **SSH keys** are removed during local cleanup
- **AWS credentials** are validated but not stored
- **Sensitive data** is not logged or cached
- **Permissions** are checked before operations

### 💰 Cost Considerations
- **Validation scripts** are read-only (no cost)
- **Cleanup scripts** may destroy resources (cost impact)
- **VPC endpoints** and **NAT gateways** are expensive
- **Monitor costs** during cleanup operations

## 🆘 Troubleshooting

### Common Issues
1. **Permission denied**: Check script permissions with `chmod +x`
2. **AWS credentials**: Run `aws configure` to set up credentials
3. **Tool not found**: Install required tools (AWS CLI, Terraform, Terragrunt)
4. **Resource not found**: Verify infrastructure is deployed

### Getting Help
1. **Check prerequisites**: Run `./scripts/validation/validate.sh prereq`
2. **Test connectivity**: Run `./scripts/quick-validation.sh`
3. **Review logs**: Check script output for error messages
4. **Consult documentation**: Review project README and getting-started guide

---

**Happy Infrastructure Management! 🎉**
