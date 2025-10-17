#!/bin/bash

# Quick validation script to test infrastructure

echo "=== QUICK INFRASTRUCTURE VALIDATION ==="

# Test 1: AWS Connectivity
echo "Test 1: AWS Connectivity"
if aws sts get-caller-identity &> /dev/null; then
    echo "✅ AWS credentials working"
    aws sts get-caller-identity --query 'Account' --output text
else
    echo "❌ AWS credentials not working"
fi

# Test 2: Check VPC
echo ""
echo "Test 2: VPC Status"
VPC_ID="vpc-0bfba57d9c4a06de2"
if aws ec2 describe-vpcs --region us-east-1 --vpc-ids "$VPC_ID" &> /dev/null; then
    echo "✅ VPC exists: $VPC_ID"
    aws ec2 describe-vpcs --region us-east-1 --vpc-ids "$VPC_ID" --query 'Vpcs[0].{State:State,CidrBlock:CidrBlock}' --output table
else
    echo "❌ VPC not found: $VPC_ID"
fi

# Test 3: Check Subnets
echo ""
echo "Test 3: Subnets"
SUBNET_COUNT=$(aws ec2 describe-subnets --region us-east-1 --filters "Name=vpc-id,Values=$VPC_ID" --query 'length(Subnets)' --output text)
echo "✅ Found $SUBNET_COUNT subnets in VPC"

# Test 4: Check Security Groups
echo ""
echo "Test 4: Security Groups"
SG_COUNT=$(aws ec2 describe-security-groups --region us-east-1 --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=!default" --query 'length(SecurityGroups)' --output text)
echo "✅ Found $SG_COUNT custom security groups"

# Test 5: Check Internet Gateway
echo ""
echo "Test 5: Internet Gateway"
IGW_COUNT=$(aws ec2 describe-internet-gateways --region us-east-1 --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'length(InternetGateways)' --output text)
echo "✅ Found $IGW_COUNT internet gateway(s)"

# Test 6: Check VPC Endpoints
echo ""
echo "Test 6: VPC Endpoints"
ENDPOINT_COUNT=$(aws ec2 describe-vpc-endpoints --region us-east-1 --filters "Name=vpc-id,Values=$VPC_ID" --query 'length(VpcEndpoints)' --output text)
echo "✅ Found $ENDPOINT_COUNT VPC endpoint(s)"

# Test 7: Check S3 Bucket
echo ""
echo "Test 7: S3 Bucket"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
BUCKET_NAME="terraform-terragrunt-state-${ACCOUNT_ID}"
if aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
    echo "✅ S3 bucket exists: $BUCKET_NAME"
else
    echo "❌ S3 bucket not found: $BUCKET_NAME"
fi

# Test 8: Check DynamoDB Table
echo ""
echo "Test 8: DynamoDB Table"
if aws dynamodb describe-table --region us-east-1 --table-name terraform-terragrunt-locks &> /dev/null; then
    echo "✅ DynamoDB table exists: terraform-terragrunt-locks"
else
    echo "❌ DynamoDB table not found: terraform-terragrunt-locks"
fi

echo ""
echo "=== QUICK VALIDATION COMPLETED ==="
