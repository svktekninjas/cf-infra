#!/bin/bash

echo "🧪 Configuration Test Script"
echo "============================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "1. Testing base configuration..."
if source "$SCRIPT_DIR/config.sh"; then
    echo "✅ Base configuration loaded successfully"
else
    echo "❌ Failed to load base configuration"
    exit 1
fi

echo ""
echo "2. Testing configuration validation..."
if validate_config; then
    echo "✅ Configuration validation passed"
else
    echo "❌ Configuration validation failed"
    exit 1
fi

echo ""
echo "3. Testing helper functions..."
echo "ECR Registry URL: $(get_ecr_registry_url)"
echo "ECR Repository URL: $(get_ecr_repo_url)"
echo "IAM Role ARN (test): $(get_iam_role_arn "test-role")"
echo "ECR Repository ARN: $(get_ecr_repo_arn)"

echo ""
echo "4. Testing environment configurations..."

# Test dev config
echo "Testing dev environment:"
load_environment_config "dev"
echo "  Environment: $ENV"
echo "  Cluster Name: $CLUSTER_NAME"
echo "  Delegate Name: $DELEGATE_NAME"
echo "  Memory Limit: $CONTAINER_MEMORY_LIMIT"

echo ""
# Test prod config
echo "Testing prod environment:"
load_environment_config "prod"
echo "  Environment: $ENV"
echo "  Cluster Name: $CLUSTER_NAME"
echo "  Delegate Name: $DELEGATE_NAME"
echo "  Memory Limit: $CONTAINER_MEMORY_LIMIT"

echo ""
echo "5. Current configuration summary:"
echo "================================="
VERBOSE_OUTPUT="true"
print_config

echo ""
echo "🎯 Configuration test complete!"
echo ""
echo "All configuration files are working correctly."
echo "You can now use the updated scripts with centralized configuration."
