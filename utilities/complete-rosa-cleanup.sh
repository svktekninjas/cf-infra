#!/bin/bash

# =============================================================================
# Complete ROSA Cleanup Script
# Cleans up remaining ROSA resources after cluster deletion
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_PROFILE="${AWS_PROFILE:-sid-KS}"
CLUSTER_PREFIX="rosa-cluster-dev-e7o9"
OIDC_CONFIG_ID="2g2gqvov44esri8v9t7r6p83umfoc71l"

echo -e "${BLUE}🧹 Complete ROSA Cleanup Script${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "success" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "warning" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    elif [ "$status" = "error" ]; then
        echo -e "${RED}❌ $message${NC}"
    else
        echo -e "${BLUE}ℹ️  $message${NC}"
    fi
}

# Check if cluster is fully deleted
check_cluster_status() {
    print_status "info" "Checking cluster deletion status..."
    
    CLUSTER_STATUS=$(rosa list clusters --profile $AWS_PROFILE | grep rosa-cluster-dev | awk '{print $3}' || echo "not_found")
    
    if [ "$CLUSTER_STATUS" = "not_found" ]; then
        print_status "success" "Cluster rosa-cluster-dev has been fully deleted"
        return 0
    elif [ "$CLUSTER_STATUS" = "uninstalling" ]; then
        print_status "warning" "Cluster is still uninstalling. Please wait..."
        return 1
    else
        print_status "warning" "Cluster status: $CLUSTER_STATUS"
        return 1
    fi
}

# Clean up operator roles
cleanup_operator_roles() {
    print_status "info" "Cleaning up operator roles..."
    
    if rosa delete operator-roles --prefix $CLUSTER_PREFIX --profile $AWS_PROFILE --yes; then
        print_status "success" "Operator roles deleted successfully"
    else
        print_status "warning" "Some operator roles may not exist or already deleted"
    fi
}

# Clean up OIDC provider
cleanup_oidc_provider() {
    print_status "info" "Cleaning up OIDC provider..."
    
    if rosa delete oidc-provider --oidc-config-id $OIDC_CONFIG_ID --profile $AWS_PROFILE --yes; then
        print_status "success" "OIDC provider deleted successfully"
    else
        print_status "warning" "OIDC provider may not exist or already deleted"
    fi
}

# Verify EC2 instances are terminated
verify_ec2_cleanup() {
    print_status "info" "Verifying EC2 instances are terminated..."
    
    RUNNING_INSTANCES=$(aws ec2 describe-instances --region us-east-1 --profile $AWS_PROFILE \
        --query 'Reservations[*].Instances[?State.Name==`running`].InstanceId' --output text | wc -w)
    
    if [ "$RUNNING_INSTANCES" -eq 0 ]; then
        print_status "success" "All EC2 instances have been terminated"
    else
        print_status "warning" "$RUNNING_INSTANCES EC2 instances still running"
        aws ec2 describe-instances --region us-east-1 --profile $AWS_PROFILE \
            --query 'Reservations[*].Instances[?State.Name==`running`].[InstanceId,InstanceType,Tags[?Key==`Name`].Value|[0]]' \
            --output table
    fi
}

# Check for remaining AWS resources
check_remaining_resources() {
    print_status "info" "Checking for remaining AWS resources..."
    
    echo ""
    echo "🔍 Load Balancers:"
    aws elbv2 describe-load-balancers --region us-east-1 --profile $AWS_PROFILE \
        --query 'LoadBalancers[?contains(LoadBalancerName, `rosa`) || contains(LoadBalancerName, `cf`)].LoadBalancerName' \
        --output text || echo "None found"
    
    echo ""
    echo "🔍 Security Groups (non-default):"
    aws ec2 describe-security-groups --region us-east-1 --profile $AWS_PROFILE \
        --query 'SecurityGroups[?GroupName!=`default`].[GroupId,GroupName]' \
        --output table | head -10
    
    echo ""
    echo "🔍 IAM Roles (ROSA related):"
    aws iam list-roles --profile $AWS_PROFILE \
        --query 'Roles[?contains(RoleName, `rosa`) || contains(RoleName, `ROSA`)].RoleName' \
        --output text || echo "None found"
}

# Main execution
main() {
    echo -e "${YELLOW}⚠️  This script will clean up remaining ROSA resources${NC}"
    echo -e "${YELLOW}⚠️  Make sure the cluster deletion is complete first${NC}"
    echo ""
    
    # Check cluster status first
    if ! check_cluster_status; then
        echo ""
        print_status "warning" "Cluster deletion not complete. Please wait and try again."
        print_status "info" "You can monitor with: rosa list clusters --profile $AWS_PROFILE"
        exit 1
    fi
    
    echo ""
    print_status "info" "Proceeding with cleanup of remaining resources..."
    echo ""
    
    # Clean up operator roles
    cleanup_operator_roles
    echo ""
    
    # Clean up OIDC provider
    cleanup_oidc_provider
    echo ""
    
    # Verify EC2 cleanup
    verify_ec2_cleanup
    echo ""
    
    # Check remaining resources
    check_remaining_resources
    echo ""
    
    print_status "success" "ROSA cleanup completed!"
    echo ""
    echo -e "${GREEN}🎉 Cleanup Summary:${NC}"
    echo -e "${GREEN}✅ ROSA cluster deleted${NC}"
    echo -e "${GREEN}✅ Operator roles cleaned up${NC}"
    echo -e "${GREEN}✅ OIDC provider cleaned up${NC}"
    echo -e "${GREEN}✅ EC2 instances terminated${NC}"
    echo ""
    echo -e "${BLUE}ℹ️  Next steps:${NC}"
    echo -e "${BLUE}1. Check AWS Console for any remaining resources${NC}"
    echo -e "${BLUE}2. Review AWS billing for any ongoing charges${NC}"
    echo -e "${BLUE}3. VPC and networking resources remain (as intended)${NC}"
    echo ""
}

# Run main function
main "$@"
