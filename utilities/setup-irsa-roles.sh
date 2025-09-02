#!/bin/bash

echo "🔐 IRSA (IAM Roles for Service Accounts) Setup Script"
echo "===================================================="

REGION="us-east-1"
NAMESPACE="harness-delegate-ng"
SERVICE_ACCOUNT="cf-deploy"
ECR_REPO="harness-delegate"
AWS_ACCOUNT="818140567777"  # Single AWS account

# Get current cluster connection dynamically
CURRENT_API_URL=$(oc whoami --show-server 2>/dev/null)
CURRENT_USER=$(oc whoami 2>/dev/null)

# Get cluster and AWS info
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

echo "Account ID: $ACCOUNT_ID"
echo "Current Cluster: $CURRENT_API_URL"
echo "Current User: $CURRENT_USER"
echo "Namespace: $NAMESPACE"
echo "Service Account: $SERVICE_ACCOUNT"
echo ""

# Check cluster connection
if [ "$CURRENT_API_URL" = "" ] || [ "$CURRENT_USER" = "" ]; then
    echo "❌ Not logged into OpenShift cluster"
    echo "Please login first"
    exit 1
fi

echo "✅ Connected to cluster as: $CURRENT_USER"
echo ""

# Get OIDC issuer from current cluster
echo "1. Getting OIDC issuer from current cluster..."
OIDC_ISSUER=$(oc get authentication cluster -o jsonpath='{.spec.serviceAccountIssuer}' 2>/dev/null | sed 's|https://||')

if [ "$OIDC_ISSUER" = "" ]; then
    echo "⚠️  Could not get OIDC issuer from cluster authentication"
    echo "Trying alternative method..."
    
    # Try to get from service account token
    OIDC_ISSUER=$(oc create token default -n default --duration=1s 2>/dev/null | cut -d'.' -f2 | base64 -d 2>/dev/null | jq -r '.iss' 2>/dev/null | sed 's|https://||')
fi

if [ "$OIDC_ISSUER" = "" ]; then
    echo "❌ Could not determine OIDC issuer for current cluster"
    echo "This cluster may not support IRSA or may not be properly configured"
    echo ""
    echo "Alternative: Using traditional ECR authentication (already configured)"
    echo "Your ECR authentication should work with the secrets created earlier"
    exit 0
fi

echo "✅ OIDC Issuer: $OIDC_ISSUER"
echo ""

# Create trust policy for IRSA
echo "2. Creating IRSA trust policy..."
TRUST_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/$OIDC_ISSUER"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "$OIDC_ISSUER:sub": "system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT",
                    "$OIDC_ISSUER:aud": "openshift"
                }
            }
        }
    ]
}
EOF
)

# Create ECR access policy
ECR_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:DescribeRepositories",
                "ecr:ListImages"
            ],
            "Resource": [
                "arn:aws:ecr:$REGION:$AWS_ACCOUNT:repository/$ECR_REPO",
                "arn:aws:ecr:$REGION:$AWS_ACCOUNT:repository/*"
            ]
        }
    ]
}
EOF
)

# Create IAM role for service account
ROLE_NAME="current-cluster-harness-delegate-irsa"
echo "3. Creating IAM role: $ROLE_NAME"

# Check if OIDC provider exists
echo "Checking if OIDC provider exists..."
OIDC_PROVIDER_EXISTS=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?ends_with(Arn, '$OIDC_ISSUER')]" --output text)

if [ "$OIDC_PROVIDER_EXISTS" = "" ]; then
    echo "⚠️  OIDC provider does not exist for this cluster"
    echo "This cluster may not support IRSA"
    echo ""
    echo "Using traditional ECR authentication instead (already configured)"
    echo "Your ECR secrets should work fine without IRSA"
    exit 0
fi

echo "✅ OIDC provider exists"

# Check if role exists
if aws iam get-role --role-name "$ROLE_NAME" &>/dev/null; then
    echo "✅ Role $ROLE_NAME already exists"
else
    # Create role
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document "$TRUST_POLICY" \
        --description "IRSA role for Harness delegate in current cluster" \
        --tags Key=Purpose,Value=HarnessDelegate Key=Cluster,Value=current
    
    if [ $? -eq 0 ]; then
        echo "✅ Created IAM role: $ROLE_NAME"
    else
        echo "❌ Failed to create IAM role"
        exit 1
    fi
fi

# Create and attach ECR policy
POLICY_NAME="current-cluster-harness-delegate-ecr-policy"
echo "4. Creating ECR policy: $POLICY_NAME"

# Check if policy exists
POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)

if [ "$POLICY_ARN" != "" ]; then
    echo "✅ Policy already exists: $POLICY_ARN"
else
    # Create policy
    POLICY_ARN=$(aws iam create-policy \
        --policy-name "$POLICY_NAME" \
        --policy-document "$ECR_POLICY" \
        --description "ECR access policy for Harness delegate" \
        --query 'Policy.Arn' --output text)
    
    if [ $? -eq 0 ]; then
        echo "✅ Created policy: $POLICY_ARN"
    else
        echo "❌ Failed to create policy"
        exit 1
    fi
fi

# Attach policy to role
echo "5. Attaching policy to role..."
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN"
if [ $? -eq 0 ]; then
    echo "✅ Policy attached to role"
else
    echo "❌ Failed to attach policy to role"
fi

# Update service account with IRSA annotation
echo "6. Updating service account with IRSA annotation..."
ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"

# Create/update service account
cat <<EOF | oc apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SERVICE_ACCOUNT
  namespace: $NAMESPACE
  annotations:
    eks.amazonaws.com/role-arn: $ROLE_ARN
  labels:
    app: harness-delegate
    component: irsa-service-account
EOF

echo "✅ Service account updated with IRSA annotation"
echo ""

# Create similar setup for deployment service accounts
echo "7. Setting up IRSA for deployment service accounts..."
DEPLOY_NAMESPACES=("cf-monitor" "cf-app" "cf-dev")

for ns in "${DEPLOY_NAMESPACES[@]}"; do
    echo "Setting up IRSA for namespace: $ns"
    
    # Create namespace
    oc create namespace $ns --dry-run=client -o yaml | oc apply -f -
    
    # Create deployment role
    DEPLOY_ROLE_NAME="current-cluster-$ns-deployer-irsa"
    
    # Trust policy for deployment SA
    DEPLOY_TRUST_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/$OIDC_ISSUER"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "$OIDC_ISSUER:sub": "system:serviceaccount:$ns:ecr-sa",
                    "$OIDC_ISSUER:aud": "openshift"
                }
            }
        }
    ]
}
EOF
)
    
    # Create deployment role if it doesn't exist
    if ! aws iam get-role --role-name "$DEPLOY_ROLE_NAME" &>/dev/null; then
        aws iam create-role \
            --role-name "$DEPLOY_ROLE_NAME" \
            --assume-role-policy-document "$DEPLOY_TRUST_POLICY" \
            --description "IRSA role for deployments in $ns namespace" \
            --tags Key=Cluster,Value=current Key=Namespace,Value=$ns
        
        # Attach ECR policy
        aws iam attach-role-policy --role-name "$DEPLOY_ROLE_NAME" --policy-arn "$POLICY_ARN"
        
        echo "✅ Created deployment role: $DEPLOY_ROLE_NAME"
    else
        echo "✅ Deployment role already exists: $DEPLOY_ROLE_NAME"
    fi
    
    # Create/update service account
    DEPLOY_ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$DEPLOY_ROLE_NAME"
    cat <<EOF | oc apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ecr-sa
  namespace: $ns
  annotations:
    eks.amazonaws.com/role-arn: $DEPLOY_ROLE_ARN
  labels:
    app: harness-delegate
    component: deployment-sa
EOF
    
    echo "✅ Updated service account ecr-sa in $ns"
done
echo ""

# Test IRSA setup
echo "8. Testing IRSA setup..."

# Create test pod to verify IRSA
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: irsa-test-pod
  namespace: $NAMESPACE
spec:
  serviceAccountName: $SERVICE_ACCOUNT
  containers:
  - name: aws-cli
    image: amazon/aws-cli:latest
    command: ['sleep', '300']
  restartPolicy: Never
EOF

echo "Waiting for test pod..."
oc wait --for=condition=Ready pod/irsa-test-pod -n $NAMESPACE --timeout=60s

if [ $? -eq 0 ]; then
    echo "✅ Test pod ready"
    
    # Test AWS identity
    echo "Testing AWS identity from pod:"
    oc exec irsa-test-pod -n $NAMESPACE -- aws sts get-caller-identity
    
    # Test ECR access
    echo "Testing ECR access:"
    oc exec irsa-test-pod -n $NAMESPACE -- aws ecr get-authorization-token --region $REGION --output text
    
    # Cleanup
    oc delete pod irsa-test-pod -n $NAMESPACE
else
    echo "⚠️  Test pod failed to start"
fi
echo ""

echo "🎯 IRSA Setup Complete!"
echo ""
echo "Summary:"
echo "- Created IAM role: $ROLE_NAME"
echo "- Created ECR policy: $POLICY_NAME"
echo "- Updated service account: $SERVICE_ACCOUNT in $NAMESPACE"
echo "- Set up deployment service accounts in target namespaces"
echo ""
echo "Role ARNs created:"
echo "- Delegate: arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"
for ns in "${DEPLOY_NAMESPACES[@]}"; do
    echo "- $ns: arn:aws:iam::$ACCOUNT_ID:role/current-cluster-$ns-deployer-irsa"
done
echo ""
echo "Next steps:"
echo "1. Wait 1-2 minutes for IAM propagation"
echo "2. Test ECR authentication"
echo "3. Deploy Harness delegate"
echo ""
echo "To verify IRSA is working:"
echo "oc run test-pod --image=amazon/aws-cli:latest --serviceaccount=$SERVICE_ACCOUNT -n $NAMESPACE -- aws sts get-caller-identity"
