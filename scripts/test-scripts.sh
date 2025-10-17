#!/bin/bash

# Simple test script for cleanup and validation scripts

echo "=== TESTING CLEANUP AND VALIDATION SCRIPTS ==="

# Test cleanup script help
echo "Testing cleanup script help..."
./scripts/cleanup/cleanup.sh 2>&1 | head -10

echo ""
echo "Testing validation script help..."
./scripts/validation/validate.sh 2>&1 | head -10

echo ""
echo "Testing AWS connectivity..."
aws sts get-caller-identity

echo ""
echo "Testing Terragrunt version..."
terragrunt --version

echo ""
echo "Testing Terraform version..."
terraform --version

echo ""
echo "=== SCRIPTS TEST COMPLETED ==="
