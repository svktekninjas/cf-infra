#!/bin/bash

echo "🔧 ROSA RBAC Fix Script for Harness Delegate"
echo "============================================"

NAMESPACE="harness-delegate-ng"
SERVICE_ACCOUNT="cf-deploy"
DELEGATE_NAME="rosa-harness-delegate-dev"

echo "Namespace: $NAMESPACE"
echo "Service Account: $SERVICE_ACCOUNT"
echo ""

# Check cluster connection
if ! oc whoami &>/dev/null; then
    echo "❌ Not logged into OpenShift cluster"
    echo "Please login first"
    exit 1
fi

echo "✅ Connected as: $(oc whoami)"
echo ""

# Create namespace
echo "1. Creating/verifying namespace..."
oc create namespace $NAMESPACE --dry-run=client -o yaml | oc apply -f -
echo "✅ Namespace $NAMESPACE ready"
echo ""

# Create service account
echo "2. Creating service account..."
cat <<EOF | oc apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SERVICE_ACCOUNT
  namespace: $NAMESPACE
  labels:
    app: harness-delegate
    component: service-account
  annotations:
    description: "Service account for Harness delegate with ECR and cluster access"
EOF

echo "✅ Service account $SERVICE_ACCOUNT created/updated"
echo ""

# Create ClusterRole for Harness delegate
echo "3. Creating ClusterRole for Harness delegate..."
cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: harness-delegate-cluster-role
  labels:
    app: harness-delegate
    component: rbac
rules:
# Core resources
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]
# Apps resources
- apiGroups: ["apps"]
  resources: ["*"]
  verbs: ["*"]
# Extensions resources
- apiGroups: ["extensions"]
  resources: ["*"]
  verbs: ["*"]
# Networking resources
- apiGroups: ["networking.k8s.io"]
  resources: ["*"]
  verbs: ["*"]
# RBAC resources
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["*"]
  verbs: ["*"]
# Custom resources
- apiGroups: ["apiextensions.k8s.io"]
  resources: ["*"]
  verbs: ["*"]
# Metrics and monitoring
- apiGroups: ["metrics.k8s.io"]
  resources: ["*"]
  verbs: ["*"]
# Autoscaling
- apiGroups: ["autoscaling"]
  resources: ["*"]
  verbs: ["*"]
# Batch jobs
- apiGroups: ["batch"]
  resources: ["*"]
  verbs: ["*"]
# Storage
- apiGroups: ["storage.k8s.io"]
  resources: ["*"]
  verbs: ["*"]
# OpenShift specific
- apiGroups: ["route.openshift.io"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["image.openshift.io"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["build.openshift.io"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["apps.openshift.io"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["project.openshift.io"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["security.openshift.io"]
  resources: ["*"]
  verbs: ["*"]
EOF

echo "✅ ClusterRole created"
echo ""

# Create ClusterRoleBinding
echo "4. Creating ClusterRoleBinding..."
cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: harness-delegate-cluster-binding
  labels:
    app: harness-delegate
    component: rbac
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: harness-delegate-cluster-role
subjects:
- kind: ServiceAccount
  name: $SERVICE_ACCOUNT
  namespace: $NAMESPACE
EOF

echo "✅ ClusterRoleBinding created"
echo ""

# Create namespace-specific Role for additional permissions
echo "5. Creating namespace Role..."
cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: harness-delegate-namespace-role
  namespace: $NAMESPACE
  labels:
    app: harness-delegate
    component: rbac
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["apps"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["extensions"]
  resources: ["*"]
  verbs: ["*"]
EOF

# Create RoleBinding
cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: harness-delegate-namespace-binding
  namespace: $NAMESPACE
  labels:
    app: harness-delegate
    component: rbac
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: harness-delegate-namespace-role
subjects:
- kind: ServiceAccount
  name: $SERVICE_ACCOUNT
  namespace: $NAMESPACE
EOF

echo "✅ Namespace Role and RoleBinding created"
echo ""

# Add security context constraints for OpenShift
echo "6. Adding Security Context Constraints..."
cat <<EOF | oc apply -f -
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: harness-delegate-scc
  labels:
    app: harness-delegate
    component: security
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegedContainer: false
allowedCapabilities: []
defaultAddCapabilities: []
fsGroup:
  type: RunAsAny
readOnlyRootFilesystem: false
requiredDropCapabilities: []
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: RunAsAny
supplementalGroups:
  type: RunAsAny
volumes:
- configMap
- downwardAPI
- emptyDir
- persistentVolumeClaim
- projected
- secret
users:
- system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT
EOF

echo "✅ Security Context Constraints created"
echo ""

# Test permissions
echo "7. Testing service account permissions..."

echo "Testing basic permissions:"
echo "Can create pods: $(oc auth can-i create pods --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT)"
echo "Can create secrets: $(oc auth can-i create secrets --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT)"
echo "Can create deployments: $(oc auth can-i create deployments --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT)"
echo "Can list nodes: $(oc auth can-i list nodes --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT)"
echo "Can create services: $(oc auth can-i create services --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT)"

echo ""
echo "Testing cluster-level permissions:"
echo "Can list namespaces: $(oc auth can-i list namespaces --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT)"
echo "Can create clusterroles: $(oc auth can-i create clusterroles --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT)"
echo "Can create networkpolicies: $(oc auth can-i create networkpolicies --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT)"

echo ""
echo "Testing OpenShift-specific permissions:"
echo "Can create routes: $(oc auth can-i create routes --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT)"
echo "Can list projects: $(oc auth can-i list projects --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT)"
echo ""

# Create additional service accounts for different namespaces
echo "8. Creating service accounts for target namespaces..."
TARGET_NAMESPACES=("cf-monitor" "cf-app" "cf-dev")

for ns in "${TARGET_NAMESPACES[@]}"; do
    echo "Setting up service account in namespace: $ns"
    
    # Create namespace if it doesn't exist
    oc create namespace $ns --dry-run=client -o yaml | oc apply -f -
    
    # Create service account
    cat <<EOF | oc apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ecr-sa
  namespace: $ns
  labels:
    app: harness-delegate
    component: deployment-sa
EOF
    
    # Create role binding for deployment permissions
    cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: harness-deployer-binding
  namespace: $ns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: ecr-sa
  namespace: $ns
EOF
    
    echo "✅ Service account ecr-sa created in $ns"
done
echo ""

# Display summary
echo "9. RBAC setup summary..."
echo "Service Accounts created:"
echo "- $SERVICE_ACCOUNT in $NAMESPACE (for delegate)"
echo "- ecr-sa in cf-monitor, cf-app, cf-dev (for deployments)"
echo ""
echo "Permissions granted:"
echo "- Cluster admin permissions for delegate"
echo "- Namespace admin permissions for deployment SAs"
echo "- Security context constraints configured"
echo ""

echo "🎯 ROSA RBAC Fix Complete!"
echo ""
echo "Next steps:"
echo "1. Verify ECR authentication is set up"
echo "2. Test delegate deployment"
echo "3. Verify Harness can deploy to target namespaces"
echo ""
echo "To test deployment permissions:"
echo "oc auth can-i create deployments --as=system:serviceaccount:cf-app:ecr-sa -n cf-app"
