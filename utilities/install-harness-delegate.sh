#!/bin/bash

# =============================================================================
# Harness Delegate Installation Script
# =============================================================================
# This script installs the Harness delegate with proper ECR authentication
# =============================================================================

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Load environment-specific config if specified
if [[ -n "$1" ]]; then
    load_environment_config "$1"
fi

echo "🚀 Harness Delegate Installation Script"
echo "======================================"

# Validate configuration
if ! validate_config; then
    echo "❌ Configuration validation failed"
    exit 1
fi

# Print current configuration if verbose
print_config

# Get current cluster connection
CURRENT_API=$(oc whoami --show-server 2>/dev/null)
CURRENT_USER=$(oc whoami 2>/dev/null)

echo "Current Cluster: $CURRENT_API"
echo "Current User: $CURRENT_USER"
echo ""

echo "1. Checking prerequisites..."
# Check cluster connection
if [ "$CURRENT_API" = "" ] || [ "$CURRENT_USER" = "" ]; then
    echo "❌ Not logged into OpenShift cluster"
    echo "Please login first"
    exit 1
fi

# Check AWS CLI
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ AWS CLI not configured"
    exit 1
fi

echo "✅ Prerequisites met"

echo ""
echo "2. Creating namespace..."
oc create namespace "$NAMESPACE" --dry-run=client -o yaml | oc apply -f -
echo "✅ Namespace ready"

echo ""
echo "3. Setting up ECR authentication..."
# Get ECR login token
ECR_TOKEN=$(aws ecr get-login-password --region "$AWS_REGION")
if [ $? -ne 0 ]; then
    echo "❌ Failed to get ECR token"
    exit 1
fi

# Create ECR secret
oc delete secret "$ECR_SECRET_NAME" -n "$NAMESPACE" --ignore-not-found=true
oc create secret docker-registry "$ECR_SECRET_NAME" \
    --docker-server="$ECR_REGISTRY" \
    --docker-username=AWS \
    --docker-password="$ECR_TOKEN" \
    -n "$NAMESPACE"

echo "✅ ECR secret created"

echo ""
echo "4. Creating service account..."
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

echo "✅ Service account created"

echo ""
echo "5. Setting up RBAC..."
cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: harness-delegate-cluster-admin
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: harness-delegate-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: harness-delegate-cluster-admin
subjects:
- kind: ServiceAccount
  name: $SERVICE_ACCOUNT
  namespace: $NAMESPACE
EOF

echo "✅ RBAC configured"

echo ""
echo "6. Deploying Harness delegate..."
cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    harness.io/name: $DELEGATE_NAME
  name: $DELEGATE_NAME
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      harness.io/name: $DELEGATE_NAME
  template:
    metadata:
      labels:
        harness.io/name: $DELEGATE_NAME
      annotations:
        prometheus.io/scrape: "false"
    spec:
      terminationGracePeriodSeconds: 600
      restartPolicy: Always
      serviceAccountName: $SERVICE_ACCOUNT
      containers:
      - image: $(get_ecr_repo_url):latest
        imagePullPolicy: Always
        name: delegate
        securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 0
        resources:
          limits:
            memory: "$CONTAINER_MEMORY_LIMIT"
          requests:
            cpu: "$CONTAINER_CPU_REQUEST"
            memory: "$CONTAINER_MEMORY_REQUEST"
        livenessProbe:
          httpGet:
            path: /api/health
            port: 3460
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 2
        startupProbe:
          httpGet:
            path: /api/health
            port: 3460
            scheme: HTTP
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 15
        env:
        - name: JAVA_OPTS
          value: "$JAVA_OPTS"
        - name: ACCOUNT_ID
          value: "$HARNESS_ACCOUNT_ID"
        - name: MANAGER_HOST_AND_PORT
          value: "$HARNESS_MANAGER_HOST"
        - name: DEPLOY_MODE
          value: KUBERNETES
        - name: DELEGATE_NAME
          value: $DELEGATE_NAME
        - name: DELEGATE_TYPE
          value: "KUBERNETES"
        - name: DELEGATE_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: INIT_SCRIPT
          value: ""
        - name: DELEGATE_DESCRIPTION
          value: ""
        - name: DELEGATE_TAGS
          value: ""
        - name: NEXT_GEN
          value: "true"
        - name: CLIENT_TOOLS_DOWNLOAD_DISABLED
          value: "true"
        - name: LOG_STREAMING_SERVICE_URL
          value: "$HARNESS_LOG_SERVICE_URL"
EOF

echo "✅ Delegate deployment created"

echo ""
echo "7. Waiting for delegate to be ready..."
oc rollout status deployment/"$DELEGATE_NAME" -n "$NAMESPACE" --timeout="$DEPLOYMENT_TIMEOUT"

if [ $? -eq 0 ]; then
    echo "✅ Delegate is ready!"
else
    echo "⚠️  Delegate deployment may have issues. Checking status..."
fi

echo ""
echo "8. Checking delegate status..."
oc get pods -n "$NAMESPACE" -l harness.io/name="$DELEGATE_NAME"

echo ""
echo "9. Recent delegate logs:"
DELEGATE_POD=$(oc get pods -n "$NAMESPACE" -l harness.io/name="$DELEGATE_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ "$DELEGATE_POD" != "" ]; then
    oc logs "$DELEGATE_POD" -n "$NAMESPACE" --tail=10 2>/dev/null || echo "Could not get logs"
else
    echo "No delegate pods found"
fi

echo ""
echo "🎯 Harness Delegate Installation Complete!"
echo ""
echo "Summary:"
echo "- Delegate Name: $DELEGATE_NAME"
echo "- Namespace: $NAMESPACE"
echo "- Image: $(get_ecr_repo_url):latest"
echo "- Environment: ${ENV:-dev}"
echo ""
echo "To check status:"
echo "oc get pods -n $NAMESPACE"
echo "oc logs -f deployment/$DELEGATE_NAME -n $NAMESPACE"
echo ""
echo "If there are still issues:"
echo "1. Check ECR connectivity: ./troubleshoot-ecr-connectivity.sh"
echo "2. Check network: ./troubleshoot-network.sh"
echo "3. Fix networking: ./fix-rosa-networking.sh"
