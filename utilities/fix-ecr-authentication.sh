#!/bin/bash

# =============================================================================
# ECR Authentication Fix Script
# =============================================================================
# This script sets up ECR authentication for the Harness delegate
# =============================================================================

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Load environment-specific config if specified
if [[ -n "$1" ]]; then
    load_environment_config "$1"
fi

echo "🔧 ECR Authentication Fix Script"
echo "==============================="

# Validate configuration
if ! validate_config; then
    echo "❌ Configuration validation failed"
    exit 1
fi

# Print current configuration if verbose
print_config

echo "1. Checking cluster connectivity..."
# Check cluster connection
CURRENT_API_URL=$(oc whoami --show-server 2>/dev/null)
CURRENT_USER=$(oc whoami 2>/dev/null)

if [ "$CURRENT_API_URL" = "" ] || [ "$CURRENT_USER" = "" ]; then
    echo "❌ Not logged into OpenShift cluster"
    echo "Please login first"
    exit 1
fi

echo "✅ Connected to cluster as: $CURRENT_USER"
echo ""

echo "2. Checking AWS CLI access..."
# Check AWS CLI
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ AWS CLI not configured"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "✅ AWS Account: $ACCOUNT_ID"

# Verify we're in the correct account
if [[ "$ACCOUNT_ID" != "$AWS_ACCOUNT" ]]; then
    echo "⚠️  Warning: Current AWS account ($ACCOUNT_ID) doesn't match configured account ($AWS_ACCOUNT)"
fi
echo ""

echo "3. Ensuring namespace exists..."
# Create namespace if it doesn't exist
oc create namespace "$NAMESPACE" --dry-run=client -o yaml | oc apply -f -
echo ""

echo "4. Getting ECR login token..."
# Get ECR login token
ECR_TOKEN=$(aws ecr get-login-password --region "$AWS_REGION")
if [ $? -ne 0 ]; then
    echo "❌ Failed to get ECR token"
    exit 1
fi

echo "✅ ECR token obtained"
echo ""

echo "5. Creating/updating ECR secret..."
# Delete existing secret if it exists
oc delete secret "$ECR_SECRET_NAME" -n "$NAMESPACE" --ignore-not-found=true

# Create new ECR secret
oc create secret docker-registry "$ECR_SECRET_NAME" \
    --docker-server="$ECR_REGISTRY" \
    --docker-username=AWS \
    --docker-password="$ECR_TOKEN" \
    -n "$NAMESPACE"

if [ $? -eq 0 ]; then
    echo "✅ ECR secret created successfully"
else
    echo "❌ Failed to create ECR secret"
    exit 1
fi
echo ""

echo "6. Creating service account with ECR access..."
# Create/update service account with image pull secrets
cat <<EOF | oc apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SERVICE_ACCOUNT
  namespace: $NAMESPACE
  labels:
    app: harness-delegate
    environment: ${ENV:-dev}
imagePullSecrets:
- name: $ECR_SECRET_NAME
EOF

echo "✅ Service account created/updated"
echo ""

echo "7. Testing ECR access with a test pod..."
# Create test pod to verify ECR access
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ecr-test-pod
  namespace: $NAMESPACE
spec:
  serviceAccountName: $SERVICE_ACCOUNT
  containers:
  - name: test
    image: $(get_ecr_repo_url):latest
    command: ['sleep', '30']
  restartPolicy: Never
EOF

echo "Waiting for test pod to start..."
sleep 10

POD_STATUS=$(oc get pod ecr-test-pod -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)
echo "Pod status: $POD_STATUS"

if [ "$POD_STATUS" = "Running" ] || [ "$POD_STATUS" = "Succeeded" ]; then
    echo "✅ ECR authentication working - pod started successfully"
elif [ "$POD_STATUS" = "Pending" ]; then
    echo "⚠️  Pod not running. Checking events..."
    echo "Events:"
    oc describe pod ecr-test-pod -n "$NAMESPACE" | grep -A 10 "Events:"
else
    echo "⚠️  Pod failed to start. Status: $POD_STATUS"
fi

# Cleanup test pod
oc delete pod ecr-test-pod -n "$NAMESPACE" --ignore-not-found=true
echo ""

echo "🎯 ECR Authentication Setup Complete!"
echo ""
echo "Summary:"
echo "- ECR Registry: $ECR_REGISTRY"
echo "- Secret Name: $ECR_SECRET_NAME"
echo "- Service Account: $SERVICE_ACCOUNT"
echo "- Namespace: $NAMESPACE"
echo ""
echo "Next: Run the Harness delegate installation"
