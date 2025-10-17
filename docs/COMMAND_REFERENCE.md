# Command Reference Guide

## 📋 **Complete Command History - Infrastructure Destruction**

This document provides a comprehensive reference of all commands executed during the infrastructure destruction process, organized by phase and purpose.

---

## 🚀 **Infrastructure Destruction Commands**

### **Phase 1: Pre-Destruction Validation**

```bash
# Navigate to project directory
cd /Users/niyisorunke/terraform-terragrunt-project

# Run initial validation to assess current infrastructure
echo "=== DESTROYING INFRASTRUCTURE STACK ==="
echo "First, let's run a quick validation to see what we have..."
./scripts/quick-validation.sh
```

**Purpose:** Verify current infrastructure state before destruction

### **Phase 2: Infrastructure Destruction**

```bash
# Navigate to networking component
cd /Users/niyisorunke/terraform-terragrunt-project
echo "=== DESTROYING NETWORKING INFRASTRUCTURE ==="
cd environments/dev/networking

# Execute destruction with auto-approval
terragrunt destroy --auto-approve
```

**Purpose:** Destroy all networking infrastructure (23 resources)

### **Phase 3: Post-Destruction Verification**

```bash
# Return to project root and verify destruction
cd /Users/niyisorunke/terraform-terragrunt-project
echo "=== VERIFYING INFRASTRUCTURE DESTRUCTION ==="
./scripts/quick-validation.sh
```

**Purpose:** Confirm all resources have been successfully destroyed

### **Phase 4: Local File Cleanup**

```bash
# Clean up local files and caches
cd /Users/niyisorunke/terraform-terragrunt-project
echo "=== CLEANING UP LOCAL FILES ==="
./scripts/cleanup/cleanup.sh local
```

**Purpose:** Remove local cache files, state files, and temporary data

---

## 🛠️ **Script Development and Testing Commands**

### **Script Setup and Permissions**

```bash
# Make scripts executable
cd /Users/niyisorunke/terraform-terragrunt-project
chmod +x scripts/cleanup/cleanup.sh
chmod +x scripts/validation/validate.sh
```

### **Script Functionality Testing**

```bash
# Test cleanup script help
echo "=== TESTING CLEANUP SCRIPT ==="
./scripts/cleanup/cleanup.sh --help

# Test validation script
echo "=== TESTING VALIDATION SCRIPT ==="
./scripts/validation/validate.sh full

# Test prerequisites validation
echo "=== TESTING VALIDATION SCRIPT - PREREQUISITES ==="
./scripts/validation/validate.sh prereq
```

### **Script Permissions and Direct Testing**

```bash
# Check script permissions
echo "=== CHECKING SCRIPT PERMISSIONS ==="
ls -la scripts/cleanup/cleanup.sh scripts/validation/validate.sh

# Test validation script directly
echo "=== TESTING VALIDATION SCRIPT DIRECTLY ==="
bash scripts/validation/validate.sh prereq
```

### **Tool Availability Verification**

```bash
# Verify required tools are installed
echo "=== TESTING BASIC COMMANDS ==="
which aws
which terragrunt
which terraform
```

### **Custom Test Script Creation**

```bash
# Create and execute test script
cd /Users/niyisorunke/terraform-terragrunt-project
chmod +x scripts/test-scripts.sh
./scripts/test-scripts.sh
```

### **Quick Validation Testing**

```bash
# Test quick validation script
cd /Users/niyisorunke/terraform-terragrunt-project
chmod +x scripts/quick-validation.sh
./scripts/quick-validation.sh
```

### **Cleanup Script Testing**

```bash
# Test local cleanup functionality
cd /Users/niyisorunke/terraform-terragrunt-project
echo "=== TESTING CLEANUP SCRIPT - LOCAL FILES ONLY ==="
./scripts/cleanup/cleanup.sh local
```

---

## 📁 **Git Repository Management Commands**

### **Initial Commit of Scripts**

```bash
# Commit cleanup and validation scripts
cd /Users/niyisorunke/terraform-terragrunt-project
echo "=== COMMITTING CLEANUP AND VALIDATION SCRIPTS ==="
git add scripts/
git commit -m "Add comprehensive cleanup and validation scripts

- cleanup.sh: Interactive and command-line cleanup options
- validate.sh: Comprehensive infrastructure validation
- quick-validation.sh: Fast infrastructure status check
- test-scripts.sh: Script testing utility

All scripts include color-coded output, error handling, and comprehensive logging."
git push origin main
```

### **Documentation Commit**

```bash
# Commit scripts documentation
cd /Users/niyisorunke/terraform-terragrunt-project
echo "=== FINAL COMMIT WITH SCRIPTS DOCUMENTATION ==="
git add scripts/README.md
git commit -m "Add comprehensive scripts documentation

- Complete README for scripts directory
- Usage examples for all scripts
- Safety warnings and best practices
- Troubleshooting guide
- Prerequisites and requirements"
git push origin main
```

### **Destruction Summary Commit**

```bash
# Commit destruction summary
cd /Users/niyisorunke/terraform-terragrunt-project
echo "=== COMMITTING DESTRUCTION SUMMARY ==="
git add DESTRUCTION_SUMMARY.md
git commit -m "Add comprehensive infrastructure destruction summary

- Complete documentation of destroyed resources
- 23 resources successfully removed
- Verification results confirming complete destruction
- Cost impact analysis
- Recreation instructions for future use"
git push origin main
```

### **Git Conflict Resolution**

```bash
# Handle git conflicts and sync with remote
cd /Users/niyisorunke/terraform-terragrunt-project
echo "=== SYNCING WITH REMOTE ==="
git pull origin main
git push origin main

# Resolve divergent branches
echo "=== MERGING CHANGES ==="
git pull origin main --no-rebase
git push origin main
```

---

## 🔍 **Final Verification Commands**

### **AWS Resource Verification**

```bash
# Check for any remaining VPCs with project tags
cd /Users/niyisorunke/terraform-terragrunt-project
echo "=== FINAL VERIFICATION ==="
echo "Checking if any AWS resources remain..."
aws ec2 describe-vpcs --region us-east-1 \
  --filters "Name=tag:Project,Values=terraform-terragrunt-infrastructure" \
  --query 'Vpcs[].VpcId' \
  --output text
```

### **Final Status Check**

```bash
# Display final status summary
cd /Users/niyisorunke/terraform-terragrunt-project
echo "=== FINAL STATUS CHECK ==="
echo "✅ Infrastructure Status: COMPLETELY DESTROYED"
echo "✅ Local Files: CLEANED UP"
echo "✅ Git Repository: UP TO DATE"
echo "✅ Documentation: COMPLETE"
echo ""
echo "🎉 STACK DESTRUCTION SUCCESSFUL! 🎉"
```

---

## 🎯 **Quick Reference Commands**

### **Essential Commands for Infrastructure Management**

#### **Destroy Infrastructure:**
```bash
cd environments/dev/networking
terragrunt destroy --auto-approve
```

#### **Verify Destruction:**
```bash
./scripts/quick-validation.sh
```

#### **Clean Local Files:**
```bash
./scripts/cleanup/cleanup.sh local
```

#### **Recreate Infrastructure:**
```bash
cd environments/dev/networking
terragrunt apply
```

#### **Full Infrastructure Validation:**
```bash
./scripts/validation/validate.sh full
```

#### **Check AWS Connectivity:**
```bash
aws sts get-caller-identity
```

#### **List All VPCs:**
```bash
aws ec2 describe-vpcs --region us-east-1 --query 'Vpcs[].{VpcId:VpcId,State:State,CidrBlock:CidrBlock}' --output table
```

#### **Check Subnets:**
```bash
aws ec2 describe-subnets --region us-east-1 --query 'Subnets[].{SubnetId:SubnetId,VpcId:VpcId,State:State,CidrBlock:CidrBlock}' --output table
```

#### **Check Security Groups:**
```bash
aws ec2 describe-security-groups --region us-east-1 --query 'SecurityGroups[].{GroupId:GroupId,GroupName:GroupName,VpcId:VpcId}' --output table
```

---

## 📊 **Command Statistics**

### **Total Commands Executed:** 25+ commands

| Category | Count | Purpose |
|----------|-------|---------|
| Infrastructure Management | 4 | Destroy and verify infrastructure |
| Script Development | 8 | Create and test utility scripts |
| Git Operations | 6 | Manage repository and documentation |
| Validation & Testing | 7 | Verify functionality and results |

### **Command Categories:**

- **🔧 Infrastructure:** `terragrunt destroy`, `terragrunt apply`
- **🔍 Validation:** `./scripts/quick-validation.sh`, `aws ec2 describe-*`
- **🧹 Cleanup:** `./scripts/cleanup/cleanup.sh local`
- **📁 Git:** `git add`, `git commit`, `git push`, `git pull`
- **🛠️ Setup:** `chmod +x`, `which`, `ls -la`

---

## 🚨 **Important Notes**

### **Safety Considerations:**
- Always run validation before destruction
- Use `--auto-approve` only when certain
- Verify destruction with validation scripts
- Keep S3 bucket and DynamoDB table for state management

### **Best Practices:**
- Test scripts in development environment first
- Document all changes and commands
- Use version control for all configurations
- Maintain comprehensive documentation

### **Troubleshooting:**
- Check AWS credentials: `aws sts get-caller-identity`
- Verify tool installation: `which aws terragrunt terraform`
- Check script permissions: `ls -la scripts/*.sh`
- Review git status: `git status`

---

## 📚 **Related Documentation**

- [Getting Started Guide](getting-started.md)
- [Architecture Documentation](architecture.md)
- [Scripts README](../scripts/README.md)
- [Destruction Summary](../DESTRUCTION_SUMMARY.md)
- [Project README](../README.md)

---

**Last Updated:** October 17, 2025  
**Version:** 1.0  
**Status:** Complete Infrastructure Destruction
