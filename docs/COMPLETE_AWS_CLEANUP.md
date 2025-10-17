# Complete AWS Cleanup Guide

## 🗑️ **Complete AWS Resource Cleanup Documentation**

This document provides step-by-step instructions for completely cleaning up all AWS resources, including the final deletion of S3 buckets and DynamoDB tables.

---

## 🎯 **Overview**

This cleanup process removes **ALL** AWS resources created by the Terraform + Terragrunt project, including:
- Infrastructure resources (VPCs, subnets, security groups, etc.)
- State management resources (S3 buckets, DynamoDB tables)
- Any remaining project-related resources

---

## ⚠️ **Important Warnings**

### **🚨 DESTRUCTIVE OPERATION**
- **This process is IRREVERSIBLE**
- **All data will be permanently deleted**
- **Make sure you have backups if needed**
- **This will remove ALL project resources**

### **💰 Cost Impact**
- **$0/month** after complete cleanup
- **No ongoing AWS charges**
- **All resources completely removed**

---

## 📋 **Prerequisites**

### **Required Tools**
- **AWS CLI** configured with appropriate permissions
- **Terraform** and **Terragrunt** (for infrastructure cleanup)
- **Bash** shell access

### **Required Permissions**
- **EC2 Full Access** (for VPC, subnets, security groups)
- **S3 Full Access** (for bucket deletion)
- **DynamoDB Full Access** (for table deletion)
- **IAM permissions** for resource management

---

## 🚀 **Step-by-Step Cleanup Process**

### **Phase 1: Infrastructure Cleanup**

#### **Step 1: Navigate to Project Directory**
```bash
cd /Users/niyisorunke/terraform-terragrunt-project
```

#### **Step 2: Destroy Infrastructure with Terragrunt**
```bash
# Navigate to networking component
cd environments/dev/networking

# Destroy all infrastructure resources
terragrunt destroy --auto-approve
```

**Expected Output:**
- 23 resources destroyed
- VPC, subnets, security groups removed
- Internet Gateway and VPC endpoints deleted

#### **Step 3: Verify Infrastructure Destruction**
```bash
# Return to project root
cd /Users/niyisorunke/terraform-terragrunt-project

# Run validation script
./scripts/quick-validation.sh
```

**Expected Result:**
- VPC: Not found
- Subnets: 0 found
- Security Groups: 0 found
- All infrastructure resources destroyed

---

### **Phase 2: State Management Cleanup**

#### **Step 4: Delete S3 Bucket Contents**
```bash
# Delete all objects in the S3 bucket
aws s3 rm s3://terraform-terragrunt-state-170940374732 --recursive
```

**Expected Output:**
```
delete: s3://terraform-terragrunt-state-170940374732/environments/dev/networking/terraform.tfstate
```

#### **Step 5: Delete All Object Versions**
```bash
# List and delete all object versions
aws s3api list-object-versions --bucket terraform-terragrunt-state-170940374732 \
  --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
  --output json > /tmp/versions.json

aws s3api delete-objects --bucket terraform-terragrunt-state-170940374732 \
  --delete file:///tmp/versions.json
```

**Expected Output:**
```json
{
    "Deleted": [
        {
            "Key": "environments/dev/networking/terraform.tfstate",
            "VersionId": "AcnAgG_f6BvHLeqtnfrqUuvX8KCyjQ1L"
        }
    ]
}
```

#### **Step 6: Delete Delete Markers**
```bash
# List delete markers
aws s3api list-object-versions --bucket terraform-terragrunt-state-170940374732 \
  --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' \
  --output json > /tmp/delete-markers.json

# Create proper delete markers JSON
echo '{"Objects":[{"Key":"environments/dev/networking/terraform.tfstate","VersionId":"Q1cFJDYjHqA_QALhNdqquL8IeqFXlLXy"}]}' > /tmp/delete-markers-fixed.json

# Delete delete markers
aws s3api delete-objects --bucket terraform-terragrunt-state-170940374732 \
  --delete file:///tmp/delete-markers-fixed.json
```

**Expected Output:**
```json
{
    "Deleted": [
        {
            "Key": "environments/dev/networking/terraform.tfstate",
            "VersionId": "Q1cFJDYjHqA_QALhNdqquL8IeqFXlLXy",
            "DeleteMarker": true,
            "DeleteMarkerVersionId": "Q1cFJDYjHqA_QALhNdqquL8IeqFXlLXy"
        }
    ]
}
```

#### **Step 7: Delete S3 Bucket**
```bash
# Delete the empty S3 bucket
aws s3 rb s3://terraform-terragrunt-state-170940374732
```

**Expected Output:**
```
remove_bucket: terraform-terragrunt-state-170940374732
```

#### **Step 8: Delete DynamoDB Table**
```bash
# Delete the DynamoDB table
aws dynamodb delete-table --region us-east-1 --table-name terraform-terragrunt-locks
```

**Expected Output:**
```json
{
    "TableDescription": {
        "TableName": "terraform-terragrunt-locks",
        "TableStatus": "DELETING",
        "TableArn": "arn:aws:dynamodb:us-east-1:170940374732:table/terraform-terragrunt-locks"
    }
}
```

---

### **Phase 3: Verification**

#### **Step 9: Verify S3 Bucket Deletion**
```bash
# Check if S3 bucket exists
aws s3 ls | grep terraform-terragrunt || echo "✅ S3 bucket successfully deleted"
```

**Expected Output:**
```
✅ S3 bucket successfully deleted
```

#### **Step 10: Verify DynamoDB Table Deletion**
```bash
# Check if DynamoDB table exists
aws dynamodb list-tables --region us-east-1 \
  --query 'TableNames[?contains(@, `terraform-terragrunt`)]' \
  --output table || echo "✅ DynamoDB table successfully deleted"
```

**Expected Output:**
```
✅ DynamoDB table successfully deleted
```

#### **Step 11: Comprehensive Resource Check**
```bash
# Check all AWS resources
echo "=== COMPREHENSIVE AWS RESOURCE CHECK ==="

# Check VPCs
aws ec2 describe-vpcs --region us-east-1 \
  --filters "Name=tag:Project,Values=terraform-terragrunt-infrastructure" \
  --query 'Vpcs[].{VpcId:VpcId,State:State,CidrBlock:CidrBlock}' \
  --output table

# Check Subnets
aws ec2 describe-subnets --region us-east-1 \
  --filters "Name=tag:Project,Values=terraform-terragrunt-infrastructure" \
  --query 'Subnets[].{SubnetId:SubnetId,VpcId:VpcId,State:State}' \
  --output table

# Check Security Groups
aws ec2 describe-security-groups --region us-east-1 \
  --filters "Name=tag:Project,Values=terraform-terragrunt-infrastructure" \
  --query 'SecurityGroups[].{GroupId:GroupId,GroupName:GroupName}' \
  --output table

# Check EC2 Instances
aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:Project,Values=terraform-terragrunt-infrastructure" \
  --query 'Reservations[].Instances[].{InstanceId:InstanceId,State:State.Name}' \
  --output table

# Check Load Balancers
aws elbv2 describe-load-balancers --region us-east-1 \
  --query 'LoadBalancers[?contains(Tags[?Key==`Project`].Value, `terraform-terragrunt-infrastructure`)].{LoadBalancerName:LoadBalancerName,State:State.Code}' \
  --output table

# Check RDS Instances
aws rds describe-db-instances --region us-east-1 \
  --query 'DBInstances[?contains(DBInstanceIdentifier, `terraform-terragrunt`)].{DBInstanceIdentifier:DBInstanceIdentifier,DBInstanceStatus:DBInstanceStatus}' \
  --output table

# Check EKS Clusters
aws eks list-clusters --region us-east-1 \
  --query 'clusters[?contains(@, `terraform-terragrunt`)]' \
  --output table

# Check ECS Clusters
aws ecs list-clusters --region us-east-1 \
  --query 'clusterArns[?contains(@, `terraform-terragrunt`)]' \
  --output table

# Check CloudFormation Stacks
aws cloudformation list-stacks --region us-east-1 \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --query 'StackSummaries[?contains(StackName, `terraform-terragrunt`)].{StackName:StackName,StackStatus:StackStatus}' \
  --output table
```

**Expected Output:**
All commands should return empty results, indicating no resources found.

---

## 🧹 **Local File Cleanup**

#### **Step 12: Clean Local Files**
```bash
# Clean up local files and caches
./scripts/cleanup/cleanup.sh local
```

**Expected Output:**
```
✅ Local files cleaned up
✅ Cleanup completed successfully!
```

---

## 📊 **Cleanup Results Summary**

### **✅ Successfully Deleted Resources:**

| Resource Type | Count | Status |
|---------------|-------|--------|
| VPCs | 1 | ✅ Deleted |
| Subnets | 6 | ✅ Deleted |
| Security Groups | 3 | ✅ Deleted |
| Route Tables | 4 | ✅ Deleted |
| Internet Gateways | 1 | ✅ Deleted |
| VPC Endpoints | 2 | ✅ Deleted |
| EC2 Instances | 0 | ✅ None found |
| Load Balancers | 0 | ✅ None found |
| RDS Instances | 0 | ✅ None found |
| EKS Clusters | 0 | ✅ None found |
| ECS Clusters | 0 | ✅ None found |
| CloudFormation Stacks | 0 | ✅ None found |
| S3 Buckets | 1 | ✅ Deleted |
| DynamoDB Tables | 1 | ✅ Deleted |

### **💰 Cost Impact:**
- **Before Cleanup:** ~$14.60/month
- **After Cleanup:** $0/month
- **Total Savings:** 100% cost elimination

---

## 🔄 **Recreation Process**

If you need to recreate the infrastructure in the future:

### **1. Recreate S3 Bucket and DynamoDB Table**
```bash
# Create S3 bucket for state storage
aws s3 mb s3://terraform-terragrunt-state-$(aws sts get-caller-identity --query Account --output text)

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-terragrunt-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### **2. Deploy Infrastructure**
```bash
# Navigate to networking component
cd environments/dev/networking

# Deploy infrastructure
terragrunt apply
```

---

## 🚨 **Troubleshooting**

### **Common Issues:**

#### **S3 Bucket Not Empty Error**
```bash
# If you get "BucketNotEmpty" error, force delete all versions:
aws s3api list-object-versions --bucket BUCKET_NAME \
  --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
  --output json > /tmp/versions.json

aws s3api delete-objects --bucket BUCKET_NAME \
  --delete file:///tmp/versions.json
```

#### **DynamoDB Table in Use Error**
```bash
# Wait for table to be completely deleted before recreating
aws dynamodb describe-table --table-name TABLE_NAME --region us-east-1
```

#### **Permission Denied Errors**
```bash
# Ensure your AWS credentials have sufficient permissions
aws sts get-caller-identity
```

---

## 📝 **Commands Reference**

### **Quick Cleanup Commands:**
```bash
# Complete cleanup in one go
cd environments/dev/networking && terragrunt destroy --auto-approve
cd ../../../ && aws s3 rm s3://terraform-terragrunt-state-$(aws sts get-caller-identity --query Account --output text) --recursive
aws s3 rb s3://terraform-terragrunt-state-$(aws sts get-caller-identity --query Account --output text)
aws dynamodb delete-table --table-name terraform-terragrunt-locks --region us-east-1
./scripts/cleanup/cleanup.sh local
```

### **Verification Commands:**
```bash
# Quick verification
./scripts/quick-validation.sh

# Comprehensive check
aws ec2 describe-vpcs --region us-east-1 --filters "Name=tag:Project,Values=terraform-terragrunt-infrastructure" --query 'Vpcs[].VpcId' --output text
```

---

## 📚 **Related Documentation**

- [Command Reference](COMMAND_REFERENCE.md) - Complete command history
- [Destruction Summary](../DESTRUCTION_SUMMARY.md) - Infrastructure destruction results
- [Scripts Documentation](../scripts/README.md) - Utility scripts and tools
- [Getting Started Guide](getting-started.md) - Setup and deployment guide

---

## 🎯 **Final Status**

After completing this cleanup process:

- ✅ **All AWS resources deleted**
- ✅ **$0/month in AWS costs**
- ✅ **Local files cleaned up**
- ✅ **Project completely removed from AWS**

**AWS Account Status: COMPLETELY CLEAN! 🎉**

---

**Last Updated:** October 17, 2025  
**Version:** 1.0  
**Status:** Complete AWS Cleanup Guide
