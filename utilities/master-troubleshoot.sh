#!/bin/bash

# =============================================================================
# Master Troubleshooting Script for Harness Delegate ECR Issues
# =============================================================================

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Load environment-specific config if specified
if [[ -n "$1" ]]; then
    load_environment_config "$1"
fi

echo "🔍 Master Troubleshooting Script for Harness Delegate ECR Issues"
echo "================================================================"

# Validate configuration
if ! validate_config; then
    echo "❌ Configuration validation failed"
    exit 1
fi

# Print current configuration if verbose
print_config

# Use current cluster connection instead of hardcoded cluster name
CURRENT_API_URL=$(oc whoami --show-server 2>/dev/null)
CURRENT_USER=$(oc whoami 2>/dev/null)

echo "Current Cluster: $CURRENT_API_URL"
echo "Current User: $CURRENT_USER"
echo ""

# Check if logged into any cluster
if [ "$CURRENT_API_URL" = "" ] || [ "$CURRENT_USER" = "" ]; then
    echo "❌ Not logged into any OpenShift cluster"
    echo "Please login first using:"
    echo "oc login https://api.o0r9m0f2v7l3b1c.55n4.p1.openshiftapps.com:6443 --username cluster-admin"
    exit 1
fi

echo "✅ Connected to cluster as: $CURRENT_USER"
echo "✅ Cluster endpoint: $CURRENT_API_URL"
echo ""

echo "Available troubleshooting and fix options:"
echo ""
echo "🔍 DIAGNOSTICS:"
echo "1. ECR Connectivity Test"
echo "2. Network Troubleshooting" 
echo "3. IAM Permissions Check"
echo ""
echo "🔧 FIXES:"
echo "4. Fix ECR Authentication"
echo "5. Fix ROSA Networking"
echo "6. Fix IAM Permissions"
echo "7. Fix ROSA RBAC"
echo "8. Setup IRSA (IAM Roles for Service Accounts)"
echo ""
echo "🚀 INSTALLATION:"
echo "9. Install Harness Delegate"
echo ""
echo "🎯 COMPREHENSIVE:"
echo "10. Run All Diagnostics"
echo "11. Complete Fix (IAM + IRSA + Network + RBAC + Install)"
echo "12. Quick Fix (Auth + Network + Install)"
echo ""

read -p "Select option (1-12): " choice

case $choice in
    1)
        echo "Running ECR connectivity test..."
        bash "$SCRIPT_DIR/troubleshoot-ecr-connectivity.sh" "${1:-}"
        ;;
    2)
        echo "Running network troubleshooting..."
        bash "$SCRIPT_DIR/troubleshoot-network.sh" "${1:-}"
        ;;
    3)
        echo "Running IAM permissions check..."
        bash "$SCRIPT_DIR/troubleshoot-iam-permissions.sh" "${1:-}"
        ;;
    4)
        echo "Fixing ECR authentication..."
        bash "$SCRIPT_DIR/fix-ecr-authentication.sh" "${1:-}"
        ;;
    5)
        echo "Fixing ROSA networking..."
        bash "$SCRIPT_DIR/fix-rosa-networking.sh" "${1:-}"
        ;;
    6)
        echo "Fixing IAM permissions..."
        bash "$SCRIPT_DIR/fix-iam-permissions.sh" "${1:-}"
        ;;
    7)
        echo "Fixing ROSA RBAC..."
        bash "$SCRIPT_DIR/fix-rosa-rbac.sh" "${1:-}"
        ;;
    8)
        echo "Setting up IRSA..."
        bash "$SCRIPT_DIR/setup-irsa-roles.sh" "${1:-}"
        ;;
    9)
        echo "Installing Harness delegate..."
        bash "$SCRIPT_DIR/install-harness-delegate.sh" "${1:-}"
        ;;
    10)
        echo "Running all diagnostics..."
        echo ""
        echo "=== ECR Connectivity Test ==="
        bash "$SCRIPT_DIR/troubleshoot-ecr-connectivity.sh" "${1:-}"
        echo ""
        echo "=== Network Troubleshooting ==="
        bash "$SCRIPT_DIR/troubleshoot-network.sh" "${1:-}"
        echo ""
        echo "=== IAM Permissions Check ==="
        bash "$SCRIPT_DIR/troubleshoot-iam-permissions.sh" "${1:-}"
        ;;
    11)
        echo "Running complete fix sequence..."
        echo ""
        echo "Step 1: Fixing IAM permissions..."
        bash "$SCRIPT_DIR/fix-iam-permissions.sh" "${1:-}"
        echo ""
        echo "Step 2: Setting up IRSA..."
        bash "$SCRIPT_DIR/setup-irsa-roles.sh" "${1:-}"
        echo ""
        echo "Step 3: Fixing ROSA networking..."
        bash "$SCRIPT_DIR/fix-rosa-networking.sh" "${1:-}"
        echo ""
        echo "Step 4: Fixing ROSA RBAC..."
        bash "$SCRIPT_DIR/fix-rosa-rbac.sh" "${1:-}"
        echo ""
        echo "Step 5: Fixing ECR authentication..."
        bash "$SCRIPT_DIR/fix-ecr-authentication.sh" "${1:-}"
        echo ""
        echo "Waiting $IAM_PROPAGATION_WAIT seconds for all changes to propagate..."
        sleep "$IAM_PROPAGATION_WAIT"
        echo ""
        echo "Step 6: Installing Harness delegate..."
        bash "$SCRIPT_DIR/install-harness-delegate.sh" "${1:-}"
        ;;
    12)
        echo "Running quick fix sequence..."
        echo ""
        echo "Step 1: Fixing ECR authentication..."
        bash "$SCRIPT_DIR/fix-ecr-authentication.sh" "${1:-}"
        echo ""
        echo "Step 2: Fixing ROSA networking..."
        bash "$SCRIPT_DIR/fix-rosa-networking.sh" "${1:-}"
        echo ""
        echo "Waiting 30 seconds for network changes to propagate..."
        sleep 30
        echo ""
        echo "Step 3: Installing Harness delegate..."
        bash "$SCRIPT_DIR/install-harness-delegate.sh" "${1:-}"
        ;;
    *)
        echo "Invalid option. Please select 1-12."
        exit 1
        ;;
esac

echo ""
echo "🎯 Operation complete!"
echo ""
echo "If issues persist, consider:"
echo "1. Running diagnostics (options 1-3) to identify specific problems"
echo "2. Checking AWS CloudTrail for permission denied errors"
echo "3. Verifying cluster health: oc get nodes"
echo "4. Checking Harness account configuration and API keys"
echo ""
echo "For detailed logs and troubleshooting:"
echo "- Check delegate logs: oc logs -f deployment/$DELEGATE_NAME -n $NAMESPACE"
echo "- Check events: oc get events -n $NAMESPACE --sort-by='.lastTimestamp'"
echo "- Test ECR manually: aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY"
