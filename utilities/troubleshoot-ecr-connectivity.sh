#!/bin/bash

echo "🔍 ECR Connectivity Troubleshooting Script"
echo "=========================================="

ECR_REGISTRY="818140567777.dkr.ecr.us-east-1.amazonaws.com"
NAMESPACE="harness-delegate-ng"

# Use current cluster connection
CURRENT_API_URL=$(oc whoami --show-server 2>/dev/null)
CURRENT_USER=$(oc whoami 2>/dev/null)

echo "Current Cluster: $CURRENT_API_URL"
echo "ECR Registry: $ECR_REGISTRY"
echo ""

# Check cluster connection
echo "1. Checking cluster connectivity..."
if [ "$CURRENT_API_URL" = "" ] || [ "$CURRENT_USER" = "" ]; then
    echo "❌ Not logged into OpenShift cluster"
    echo "Please login first using:"
    echo "oc login https://api.o0r9m0f2v7l3b1c.55n4.p1.openshiftapps.com:6443 --username cluster-admin"
    exit 1
fi

echo "✅ Connected to cluster as: $CURRENT_USER"
echo ""

# Check nodes
echo "2. Checking cluster nodes..."
oc get nodes -o wide
echo ""

# Check if harness namespace exists
echo "3. Checking harness-delegate-ng namespace..."
if ! oc get namespace $NAMESPACE &>/dev/null; then
    echo "⚠️  $NAMESPACE namespace doesn't exist. Creating it..."
    oc create namespace $NAMESPACE
else
    echo "✅ $NAMESPACE namespace exists"
fi
echo ""

# Test ECR connectivity from a debug pod
echo "4. Testing ECR connectivity from cluster..."
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ecr-connectivity-test
  namespace: $NAMESPACE
spec:
  containers:
  - name: test
    image: registry.redhat.io/ubi8/ubi:latest
    command: ['sleep', '3600']
  restartPolicy: Never
EOF

echo "Waiting for test pod to be ready..."
oc wait --for=condition=Ready pod/ecr-connectivity-test -n $NAMESPACE --timeout=60s

if [ $? -eq 0 ]; then
    echo "✅ Test pod is ready"
    echo ""
    
    echo "5. Testing DNS resolution..."
    oc exec -n $NAMESPACE ecr-connectivity-test -- nslookup $ECR_REGISTRY
    echo ""
    
    echo "6. Testing HTTP connectivity..."
    oc exec -n $NAMESPACE ecr-connectivity-test -- curl -I https://$ECR_REGISTRY/v2/ --max-time 10
    echo ""
    
    echo "7. Testing general internet connectivity..."
    oc exec -n $NAMESPACE ecr-connectivity-test -- curl -I https://www.google.com --max-time 10
    echo ""
    
    echo "8. Checking routing..."
    oc exec -n $NAMESPACE ecr-connectivity-test -- ip route
    echo ""
    
    # Cleanup
    oc delete pod ecr-connectivity-test -n $NAMESPACE
else
    echo "❌ Test pod failed to start"
fi

# Check existing ECR secrets
echo "9. Checking existing ECR secrets..."
oc get secrets -n $NAMESPACE | grep ecr || echo "No ECR secrets found"
echo ""

# Check service accounts
echo "10. Checking service accounts..."
oc get sa -n $NAMESPACE
echo ""

# Check for any existing harness delegate pods
echo "11. Checking existing harness delegate pods..."
oc get pods -n $NAMESPACE -l app=harness-delegate || echo "No harness delegate pods found"
echo ""

# Check events for any errors
echo "12. Checking recent events..."
oc get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10
echo ""

echo "🔍 Troubleshooting complete!"
echo ""
echo "Next steps based on results:"
echo "- If DNS fails: Check VPC DNS settings"
echo "- If HTTP fails: Check security groups and NACLs"
echo "- If internet fails: Check NAT gateway/internet gateway"
echo "- If ECR auth fails: Check IAM roles and ECR permissions"
echo ""
echo "To fix issues:"
echo "- Network problems: ./fix-rosa-networking.sh"
echo "- Authentication: ./fix-ecr-authentication.sh"
echo "- IAM permissions: ./fix-iam-permissions.sh"
