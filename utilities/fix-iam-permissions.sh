#!/bin/bash

echo "🔧 IAM Permissions Fix Script for ECR Access"
echo "============================================"

CLUSTER_NAME="rosa-cluster-dev"
ECR_REPO="harness-delegate"
REGION="us-east-1"
AWS_ACCOUNT="818140567777"  # Single AWS account

# Get cluster and AWS info
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

echo "Account ID: $ACCOUNT_ID"
echo "Cluster: $CLUSTER_NAME"
echo "ECR Repository: $ECR_REPO"
echo ""

# Check current AWS identity
echo "1. Checking current AWS identity..."
CURRENT_USER=$(aws sts get-caller-identity --query 'Arn' --output text)
echo "Current identity: $CURRENT_USER"
echo ""

# Get ROSA cluster operator roles
echo "2. Getting ROSA cluster IAM roles..."
OPERATOR_ROLES=$(rosa describe cluster -c $CLUSTER_NAME | grep "arn:aws:iam" | grep "role/")
echo "Found operator roles:"
echo "$OPERATOR_ROLES"
echo ""

# Find image registry role
IMAGE_REGISTRY_ROLE=$(echo "$OPERATOR_ROLES" | grep "image-registry" | awk '{print $2}')
WORKER_ROLE=$(rosa describe cluster -c $CLUSTER_NAME | grep "Worker:" | awk '{print $2}')

echo "Image Registry Role: $IMAGE_REGISTRY_ROLE"
echo "Worker Role: $WORKER_ROLE"
echo ""

# Create ECR policy document
echo "3. Creating ECR access policy..."
ECR_POLICY_DOC=$(cat <<EOF
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

# Create policy
POLICY_NAME="ROSAECRAccess-$CLUSTER_NAME"
echo "Creating IAM policy: $POLICY_NAME"

# Check if policy already exists
EXISTING_POLICY=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)

if [ "$EXISTING_POLICY" != "" ]; then
    echo "✅ Policy already exists: $EXISTING_POLICY"
    POLICY_ARN="$EXISTING_POLICY"
else
    # Create new policy
    POLICY_ARN=$(aws iam create-policy \
        --policy-name "$POLICY_NAME" \
        --policy-document "$ECR_POLICY_DOC" \
        --description "ECR access policy for ROSA cluster $CLUSTER_NAME" \
        --query 'Policy.Arn' --output text)
    
    if [ $? -eq 0 ]; then
        echo "✅ Created policy: $POLICY_ARN"
    else
        echo "❌ Failed to create policy"
        exit 1
    fi
fi
echo ""

# Attach policy to image registry role
echo "4. Attaching policy to image registry role..."
if [ "$IMAGE_REGISTRY_ROLE" != "" ]; then
    ROLE_NAME=$(basename "$IMAGE_REGISTRY_ROLE")
    
    # Check if policy is already attached
    ATTACHED=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query "AttachedPolicies[?PolicyArn=='$POLICY_ARN'].PolicyArn" --output text)
    
    if [ "$ATTACHED" != "" ]; then
        echo "✅ Policy already attached to $ROLE_NAME"
    else
        aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN"
        if [ $? -eq 0 ]; then
            echo "✅ Attached policy to image registry role: $ROLE_NAME"
        else
            echo "❌ Failed to attach policy to image registry role"
        fi
    fi
else
    echo "⚠️  Image registry role not found"
fi
echo ""

# Attach policy to worker role (if needed)
echo "5. Attaching policy to worker role..."
if [ "$WORKER_ROLE" != "" ]; then
    WORKER_ROLE_NAME=$(basename "$WORKER_ROLE")
    
    # Check if policy is already attached
    ATTACHED=$(aws iam list-attached-role-policies --role-name "$WORKER_ROLE_NAME" --query "AttachedPolicies[?PolicyArn=='$POLICY_ARN'].PolicyArn" --output text)
    
    if [ "$ATTACHED" != "" ]; then
        echo "✅ Policy already attached to $WORKER_ROLE_NAME"
    else
        aws iam attach-role-policy --role-name "$WORKER_ROLE_NAME" --policy-arn "$POLICY_ARN"
        if [ $? -eq 0 ]; then
            echo "✅ Attached policy to worker role: $WORKER_ROLE_NAME"
        else
            echo "❌ Failed to attach policy to worker role"
        fi
    fi
else
    echo "⚠️  Worker role not found"
fi
echo ""

# Update ECR repository policy for same-account access
echo "6. Checking ECR repository policy..."
echo "Setting up ECR repository policy for same-account access..."

ECR_REPO_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowSameAccountAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::$AWS_ACCOUNT:root"
                ]
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability"
            ]
        }
    ]
}
EOF
)

# Set repository policy
aws ecr set-repository-policy \
    --repository-name "$ECR_REPO" \
    --policy-text "$ECR_REPO_POLICY" \
    --region "$REGION" &>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ ECR repository policy updated for same-account access"
else
    echo "⚠️  Could not update ECR repository policy (may not have permissions)"
fi
echo ""

# Test ECR access
echo "7. Testing ECR access..."
echo "Testing ECR authorization token:"
if aws ecr get-authorization-token --region $REGION &>/dev/null; then
    echo "✅ Can get ECR authorization token"
else
    echo "❌ Cannot get ECR authorization token"
fi

echo "Testing ECR repository access:"
if aws ecr describe-repositories --repository-names $ECR_REPO --region $REGION &>/dev/null; then
    echo "✅ Can access ECR repository"
else
    echo "❌ Cannot access ECR repository"
fi

echo "Testing ECR image listing:"
if aws ecr list-images --repository-name $ECR_REPO --region $REGION &>/dev/null; then
    echo "✅ Can list ECR images"
else
    echo "❌ Cannot list ECR images"
fi
echo ""

echo "🎯 IAM Permissions Fix Complete!"
echo ""
echo "Summary of changes:"
echo "- Created/updated ECR access policy: $POLICY_NAME"
echo "- Attached policy to image registry role"
echo "- Attached policy to worker role"
echo "- Updated ECR repository policy for same-account access"
echo ""
echo "Wait 1-2 minutes for IAM changes to propagate, then:"
echo "1. Re-run ECR connectivity test"
echo "2. Try delegate installation again"
echo ""
echo "If issues persist:"
echo "- Check ECR repository policy"
echo "- Verify ROSA cluster can assume the roles"
echo "- Check STS trust relationships"
