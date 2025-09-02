#!/bin/bash

echo "🔐 IAM and ROSA Permissions Troubleshooting Script"
echo "================================================="

ECR_REGISTRY="818140567777.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPO="harness-delegate"
REGION="us-east-1"
NAMESPACE="harness-delegate-ng"

# Use current cluster connection
CURRENT_API_URL=$(oc whoami --show-server 2>/dev/null)
CURRENT_USER=$(oc whoami 2>/dev/null)

echo "Current Cluster: $CURRENT_API_URL"
echo "ECR Registry: $ECR_REGISTRY"
echo ""

# Check AWS CLI access and current identity
echo "1. Checking AWS CLI identity and permissions..."
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ AWS CLI not configured"
    exit 1
fi

CURRENT_AWS_USER=$(aws sts get-caller-identity --query 'Arn' --output text)
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "✅ Current AWS Identity: $CURRENT_AWS_USER"
echo "✅ Account ID: $ACCOUNT_ID"
echo ""

# Check ECR repository permissions
echo "2. Checking ECR repository permissions..."
echo "Testing ECR describe-repositories permission:"
if aws ecr describe-repositories --repository-names $ECR_REPO --region $REGION &>/dev/null; then
    echo "✅ Can describe ECR repositories"
else
    echo "❌ Cannot describe ECR repositories - check ECR permissions"
fi

echo "Testing ECR get-authorization-token permission:"
if aws ecr get-authorization-token --region $REGION &>/dev/null; then
    echo "✅ Can get ECR authorization token"
else
    echo "❌ Cannot get ECR authorization token - check ECR permissions"
fi

echo "Testing ECR list-images permission:"
if aws ecr list-images --repository-name $ECR_REPO --region $REGION &>/dev/null; then
    echo "✅ Can list ECR images"
else
    echo "❌ Cannot list ECR images - check ECR permissions"
fi
echo ""

# Check cluster connection and permissions
echo "3. Checking OpenShift cluster permissions..."
if [ "$CURRENT_API_URL" = "" ] || [ "$CURRENT_USER" = "" ]; then
    echo "❌ Not logged into OpenShift cluster"
    echo "Please login first"
    exit 1
fi

echo "✅ Logged in as: $CURRENT_USER"
echo "✅ Cluster: $CURRENT_API_URL"

# Check cluster admin permissions
echo "Testing cluster admin permissions:"
if oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
    echo "✅ Has cluster admin permissions"
else
    echo "❌ Does not have cluster admin permissions"
fi
echo ""

# Try to find ROSA cluster IAM roles by examining worker nodes
echo "4. Checking ROSA cluster IAM roles..."
echo "Getting worker node information to find IAM roles..."

# Get worker node instance IDs
WORKER_INSTANCES=$(oc get nodes -o jsonpath='{.items[*].spec.providerID}' | tr ' ' '\n' | grep -o 'i-[a-z0-9]*')

if [ "$WORKER_INSTANCES" != "" ]; then
    echo "Found worker instances: $WORKER_INSTANCES"
    
    # Get IAM instance profile from first worker
    FIRST_WORKER=$(echo $WORKER_INSTANCES | awk '{print $1}')
    INSTANCE_PROFILE=$(aws ec2 describe-instances --instance-ids $FIRST_WORKER \
        --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' --output text 2>/dev/null)
    
    if [ "$INSTANCE_PROFILE" != "" ] && [ "$INSTANCE_PROFILE" != "None" ]; then
        echo "Worker instance profile: $INSTANCE_PROFILE"
        
        # Extract role name from instance profile
        WORKER_ROLE=$(echo $INSTANCE_PROFILE | sed 's/.*instance-profile\///' | sed 's/$//')
        echo "Worker role: $WORKER_ROLE"
        
        # Check worker role policies
        echo "Worker role attached policies:"
        aws iam list-attached-role-policies --role-name "$WORKER_ROLE" --query 'AttachedPolicies[*].PolicyArn' --output table 2>/dev/null || echo "Could not list policies"
    else
        echo "⚠️  Could not find worker IAM role"
    fi
else
    echo "⚠️  Could not find worker nodes"
fi
echo ""

# Check namespace permissions
echo "5. Checking namespace permissions..."
if oc get namespace $NAMESPACE &>/dev/null; then
    echo "✅ Namespace $NAMESPACE exists"
else
    echo "⚠️  Namespace $NAMESPACE does not exist"
fi

echo "Testing namespace permissions:"
if oc auth can-i create pods --namespace=$NAMESPACE &>/dev/null; then
    echo "✅ Can create pods in $NAMESPACE"
else
    echo "❌ Cannot create pods in $NAMESPACE"
fi

if oc auth can-i create secrets --namespace=$NAMESPACE &>/dev/null; then
    echo "✅ Can create secrets in $NAMESPACE"
else
    echo "❌ Cannot create secrets in $NAMESPACE"
fi

if oc auth can-i create serviceaccounts --namespace=$NAMESPACE &>/dev/null; then
    echo "✅ Can create service accounts in $NAMESPACE"
else
    echo "❌ Cannot create service accounts in $NAMESPACE"
fi
echo ""

# Check existing service accounts and their permissions
echo "6. Checking existing service accounts..."
if oc get namespace $NAMESPACE &>/dev/null; then
    echo "Service accounts in $NAMESPACE:"
    oc get serviceaccounts -n $NAMESPACE
    
    # Check if cf-deploy service account exists
    if oc get serviceaccount cf-deploy -n $NAMESPACE &>/dev/null; then
        echo ""
        echo "cf-deploy service account details:"
        oc describe serviceaccount cf-deploy -n $NAMESPACE
        
        # Check image pull secrets
        echo ""
        echo "Image pull secrets:"
        oc get serviceaccount cf-deploy -n $NAMESPACE -o jsonpath='{.imagePullSecrets[*].name}'
        echo ""
    else
        echo "⚠️  cf-deploy service account not found"
    fi
fi
echo ""

# Check ECR secrets
echo "7. Checking ECR secrets..."
if oc get namespace $NAMESPACE &>/dev/null; then
    ECR_SECRETS=$(oc get secrets -n $NAMESPACE | grep ecr || echo "No ECR secrets found")
    echo "ECR secrets in $NAMESPACE:"
    echo "$ECR_SECRETS"
    
    if oc get secret ecr-secret -n $NAMESPACE &>/dev/null; then
        echo ""
        echo "ECR secret details:"
        oc describe secret ecr-secret -n $NAMESPACE
    fi
fi
echo ""

# Check RBAC for service account
echo "8. Checking RBAC permissions..."
if oc get serviceaccount cf-deploy -n $NAMESPACE &>/dev/null; then
    echo "Checking what cf-deploy service account can do:"
    
    # Test various permissions
    echo "Can create pods: $(oc auth can-i create pods --as=system:serviceaccount:$NAMESPACE:cf-deploy)"
    echo "Can get secrets: $(oc auth can-i get secrets --as=system:serviceaccount:$NAMESPACE:cf-deploy)"
    echo "Can list nodes: $(oc auth can-i list nodes --as=system:serviceaccount:$NAMESPACE:cf-deploy)"
    echo "Can create deployments: $(oc auth can-i create deployments --as=system:serviceaccount:$NAMESPACE:cf-deploy)"
fi
echo ""

echo "🔍 IAM and ROSA Permissions Check Complete!"
echo ""
echo "Summary of required permissions:"
echo ""
echo "AWS IAM Permissions needed:"
echo "- ecr:GetAuthorizationToken"
echo "- ecr:BatchCheckLayerAvailability"
echo "- ecr:GetDownloadUrlForLayer"
echo "- ecr:BatchGetImage"
echo "- ecr:DescribeRepositories"
echo "- ecr:ListImages"
echo ""
echo "ROSA/OpenShift Permissions needed:"
echo "- cluster-admin or equivalent"
echo "- create/manage pods, secrets, serviceaccounts"
echo "- create/manage deployments"
echo "- create/manage RBAC resources"
echo ""
echo "Next steps if issues found:"
echo "1. Fix AWS IAM permissions: ./fix-iam-permissions.sh"
echo "2. Fix ROSA RBAC: ./fix-rosa-rbac.sh"
echo "3. Re-run ECR authentication setup"
