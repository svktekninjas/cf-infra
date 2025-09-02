#!/bin/bash

echo "🗑️  Remove Old CodePipeline ECR Policies"
echo "========================================"

# List of old CodePipeline ECR policies to remove
OLD_POLICIES=(
    "CodePipeline-ECRSource-us-east-1-NamingServerCD"
    "CodePipeline-ECRSource-us-east-1-ApiGatewayCD"
    "CodePipeline-ECRSource-us-east-1-BenchProfilesServiceCD"
    "CodePipeline-ECRSource-us-east-1-SpringCloudConfigCD"
    "CodePipeline-ECRSource-us-east-1-CommonExcelServiceCD"
    "CodePipeline-ECRSource-us-east-1-DailySubmissionCD"
    "CodePipeline-ECRSource-us-east-1-PlacmentsServiceCD"
    "CodePipeline-ECRSource-us-east-1-ConsultingFirmFrontendCD"
    "CodePipeline-ECRSource-us-east-1-InterviewsServiceCD"
)

echo "Policies to be removed:"
for policy in "${OLD_POLICIES[@]}"; do
    echo "  - $policy"
done
echo ""

echo "⚠️  WARNING: This will permanently delete these IAM policies!"
echo "Make sure these CodePipeline projects are no longer active."
echo ""

read -p "Are you sure you want to proceed? (y/N): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    echo ""
    echo "🗑️  Starting policy removal..."
    
    for policy in "${OLD_POLICIES[@]}"; do
        echo ""
        echo "Processing policy: $policy"
        
        # Get policy ARN
        POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='$policy'].Arn" --output text)
        
        if [ "$POLICY_ARN" != "" ] && [ "$POLICY_ARN" != "None" ]; then
            echo "  Found policy ARN: $POLICY_ARN"
            
            # Check if policy is attached to any roles/users/groups
            echo "  Checking policy attachments..."
            
            # Check role attachments
            ATTACHED_ROLES=$(aws iam list-entities-for-policy --policy-arn "$POLICY_ARN" --query 'PolicyRoles[*].RoleName' --output text)
            
            # Check user attachments
            ATTACHED_USERS=$(aws iam list-entities-for-policy --policy-arn "$POLICY_ARN" --query 'PolicyUsers[*].UserName' --output text)
            
            # Check group attachments
            ATTACHED_GROUPS=$(aws iam list-entities-for-policy --policy-arn "$POLICY_ARN" --query 'PolicyGroups[*].GroupName' --output text)
            
            if [ "$ATTACHED_ROLES" != "" ] || [ "$ATTACHED_USERS" != "" ] || [ "$ATTACHED_GROUPS" != "" ]; then
                echo "  ⚠️  Policy is still attached to:"
                [ "$ATTACHED_ROLES" != "" ] && echo "    Roles: $ATTACHED_ROLES"
                [ "$ATTACHED_USERS" != "" ] && echo "    Users: $ATTACHED_USERS"
                [ "$ATTACHED_GROUPS" != "" ] && echo "    Groups: $ATTACHED_GROUPS"
                echo "  Detaching policy first..."
                
                # Detach from roles
                if [ "$ATTACHED_ROLES" != "" ]; then
                    for role in $ATTACHED_ROLES; do
                        echo "    Detaching from role: $role"
                        aws iam detach-role-policy --role-name "$role" --policy-arn "$POLICY_ARN"
                    done
                fi
                
                # Detach from users
                if [ "$ATTACHED_USERS" != "" ]; then
                    for user in $ATTACHED_USERS; do
                        echo "    Detaching from user: $user"
                        aws iam detach-user-policy --user-name "$user" --policy-arn "$POLICY_ARN"
                    done
                fi
                
                # Detach from groups
                if [ "$ATTACHED_GROUPS" != "" ]; then
                    for group in $ATTACHED_GROUPS; do
                        echo "    Detaching from group: $group"
                        aws iam detach-group-policy --group-name "$group" --policy-arn "$POLICY_ARN"
                    done
                fi
            fi
            
            # Delete the policy
            echo "  Deleting policy..."
            aws iam delete-policy --policy-arn "$POLICY_ARN"
            
            if [ $? -eq 0 ]; then
                echo "  ✅ Successfully deleted: $policy"
            else
                echo "  ❌ Failed to delete: $policy"
            fi
        else
            echo "  ⚠️  Policy not found: $policy"
        fi
    done
    
    echo ""
    echo "✅ Policy cleanup complete!"
    echo ""
    echo "📊 Remaining ECR policies:"
    aws iam list-policies --scope Local --query 'Policies[?contains(PolicyName, `ECR`) || contains(PolicyName, `ecr`)].{PolicyName:PolicyName,CreateDate:CreateDate}' --output table
    
else
    echo ""
    echo "❌ Policy removal cancelled. No changes made."
fi

echo ""
echo "🎯 Next Steps:"
echo "=============="
echo "1. Run service account cleanup: ./cleanup-service-accounts-iam.sh"
echo "2. Setup proper IRSA: ./master-troubleshoot.sh (option 8)"
echo "3. Complete fix: ./master-troubleshoot.sh (option 11)"
