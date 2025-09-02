#!/bin/bash

# =============================================================================
# Harness Delegate Quick Fix Script
# Companion to comprehensive-harness-delegate-troubleshooting.md
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
REGION="${REGION:-us-east-1}"
NAMESPACE="${NAMESPACE:-harness-delegate-ng}"

echo -e "${BLUE}🎯 Harness Delegate Quick Fix Script${NC}"
echo -e "${BLUE}====================================${NC}"
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

# Function to check prerequisites
check_prerequisites() {
    print_status "info" "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_status "error" "AWS CLI not found. Please install AWS CLI."
        exit 1
    fi
    
    # Check oc CLI
    if ! command -v oc &> /dev/null; then
        print_status "error" "OpenShift CLI (oc) not found. Please install oc."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &>/dev/null; then
        print_status "error" "AWS credentials not configured for profile: $AWS_PROFILE"
        exit 1
    fi
    
    # Check cluster connection
    if ! oc whoami &>/dev/null; then
        print_status "error" "Not connected to OpenShift cluster. Please login first."
        exit 1
    fi
    
    print_status "success" "All prerequisites met"
}

# Function to diagnose the issue
diagnose_issue() {
    print_status "info" "Diagnosing Harness delegate issue..."
    
    # Check pod status
    echo ""
    echo "Current pod status:"
    oc get pods -n "$NAMESPACE" | grep harness-delegate || print_status "warning" "No Harness delegate pods found"
    
    # Check recent events
    echo ""
    echo "Recent events:"
    oc get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -5
    
    # Test ECR connectivity
    echo ""
    print_status "info" "Testing ECR connectivity..."
    if aws ecr get-login-password --region "$REGION" --profile "$AWS_PROFILE" &>/dev/null; then
        print_status "success" "ECR authentication working"
    else
        print_status "error" "ECR authentication failed"
        return 1
    fi
}

# Function to find VPC and route tables
find_vpc_info() {
    print_status "info" "Finding VPC and route table information..."
    
    # Get cluster node IPs
    NODE_IPS=$(oc get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' | tr ' ' '\n' | head -3)
    print_status "info" "Cluster node IPs: $(echo $NODE_IPS | tr '\n' ' ')"
    
    # Find VPC containing these IPs
    for vpc in $(aws ec2 describe-vpcs --profile "$AWS_PROFILE" --query 'Vpcs[*].VpcId' --output text); do
        echo "Checking VPC: $vpc"
        
        # Check if any subnet in this VPC contains our node IPs
        SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" --profile "$AWS_PROFILE" --query 'Subnets[*].[SubnetId,CidrBlock]' --output text)
        
        while read -r subnet cidr; do
            if [ -n "$cidr" ]; then
                # Check if any node IP is in this CIDR (simplified check)
                FIRST_NODE_IP=$(echo "$NODE_IPS" | head -1)
                if [[ "$FIRST_NODE_IP" == ${cidr%/*}* ]]; then
                    export CLUSTER_VPC="$vpc"
                    print_status "success" "Found cluster VPC: $vpc"
                    return 0
                fi
            fi
        done <<< "$SUBNETS"
    done
    
    print_status "warning" "Could not automatically detect VPC. Using default: vpc-075da49e833c3ce06"
    export CLUSTER_VPC="vpc-075da49e833c3ce06"
}

# Function to check route tables
check_route_tables() {
    print_status "info" "Checking route tables in VPC: $CLUSTER_VPC"
    
    # Get all route tables in VPC
    ROUTE_TABLES=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$CLUSTER_VPC" --profile "$AWS_PROFILE" --query 'RouteTables[*].RouteTableId' --output text)
    
    echo "Route tables found: $ROUTE_TABLES"
    
    # Check each route table for internet routes
    for rt in $ROUTE_TABLES; do
        echo ""
        echo "Checking route table: $rt"
        
        # Check if it's the main route table
        IS_MAIN=$(aws ec2 describe-route-tables --route-table-ids "$rt" --profile "$AWS_PROFILE" --query 'RouteTables[0].Associations[?Main==`true`]' --output text)
        
        if [ -n "$IS_MAIN" ]; then
            echo "  → This is the MAIN route table"
            export MAIN_ROUTE_TABLE="$rt"
        fi
        
        # Check for internet routes
        INTERNET_ROUTE=$(aws ec2 describe-route-tables --route-table-ids "$rt" --profile "$AWS_PROFILE" --query 'RouteTables[0].Routes[?DestinationCidrBlock==`0.0.0.0/0`]' --output text)
        
        if [ -n "$INTERNET_ROUTE" ]; then
            print_status "success" "  Has internet route (0.0.0.0/0)"
        else
            print_status "warning" "  Missing internet route (0.0.0.0/0)"
            if [ -n "$IS_MAIN" ]; then
                export NEEDS_ROUTE_FIX="true"
            fi
        fi
    done
}

# Function to find NAT Gateway
find_nat_gateway() {
    print_status "info" "Finding NAT Gateway in VPC: $CLUSTER_VPC"
    
    NAT_GATEWAY=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$CLUSTER_VPC" "Name=state,Values=available" --profile "$AWS_PROFILE" --query 'NatGateways[0].NatGatewayId' --output text)
    
    if [ "$NAT_GATEWAY" != "None" ] && [ -n "$NAT_GATEWAY" ]; then
        export NAT_GATEWAY_ID="$NAT_GATEWAY"
        print_status "success" "Found NAT Gateway: $NAT_GATEWAY"
        
        # Check NAT Gateway health
        NAT_STATE=$(aws ec2 describe-nat-gateways --nat-gateway-ids "$NAT_GATEWAY" --profile "$AWS_PROFILE" --query 'NatGateways[0].State' --output text)
        print_status "info" "NAT Gateway state: $NAT_STATE"
    else
        print_status "error" "No NAT Gateway found in VPC"
        return 1
    fi
}

# Function to apply the fix
apply_fix() {
    if [ "$NEEDS_ROUTE_FIX" = "true" ] && [ -n "$MAIN_ROUTE_TABLE" ] && [ -n "$NAT_GATEWAY_ID" ]; then
        print_status "warning" "Main route table missing internet route. Applying fix..."
        
        echo ""
        echo "Adding route: 0.0.0.0/0 -> $NAT_GATEWAY_ID in route table $MAIN_ROUTE_TABLE"
        
        if aws ec2 create-route \
            --route-table-id "$MAIN_ROUTE_TABLE" \
            --destination-cidr-block 0.0.0.0/0 \
            --nat-gateway-id "$NAT_GATEWAY_ID" \
            --profile "$AWS_PROFILE" &>/dev/null; then
            
            print_status "success" "Route added successfully!"
            
            # Verify the fix
            sleep 2
            ROUTE_CHECK=$(aws ec2 describe-route-tables --route-table-ids "$MAIN_ROUTE_TABLE" --profile "$AWS_PROFILE" --query 'RouteTables[0].Routes[?DestinationCidrBlock==`0.0.0.0/0`]' --output text)
            
            if [ -n "$ROUTE_CHECK" ]; then
                print_status "success" "Route verification successful"
                return 0
            else
                print_status "error" "Route verification failed"
                return 1
            fi
        else
            print_status "error" "Failed to add route. Route may already exist or insufficient permissions."
            return 1
        fi
    else
        print_status "info" "No route fix needed or insufficient information"
        return 0
    fi
}

# Function to test the fix
test_fix() {
    print_status "info" "Testing the fix..."
    
    # Delete old failing pods
    print_status "info" "Deleting old failing pods..."
    oc delete pods -l harness.io/name=rosa-harness-delegate-dev -n "$NAMESPACE" --ignore-not-found=true
    
    # Wait for new pods
    print_status "info" "Waiting for new pods to be created..."
    sleep 30
    
    # Check new pod status
    echo ""
    echo "New pod status:"
    oc get pods -n "$NAMESPACE" | grep harness-delegate || print_status "warning" "No pods found yet"
    
    # Create a test pod to verify connectivity
    print_status "info" "Creating test pod to verify ECR connectivity..."
    
    cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ecr-connectivity-test
  namespace: $NAMESPACE
spec:
  serviceAccountName: cf-deploy
  containers:
  - name: test
    image: busybox:latest
    command: ['sleep', '300']
  restartPolicy: Never
EOF

    # Monitor test pod
    print_status "info" "Monitoring test pod for 60 seconds..."
    sleep 60
    
    TEST_STATUS=$(oc get pod ecr-connectivity-test -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
    
    if [ "$TEST_STATUS" = "Running" ]; then
        print_status "success" "Test pod is running - connectivity restored!"
    elif [ "$TEST_STATUS" = "Pending" ]; then
        print_status "warning" "Test pod still pending - may need more time"
    else
        print_status "warning" "Test pod status: $TEST_STATUS"
    fi
    
    # Clean up test pod
    oc delete pod ecr-connectivity-test -n "$NAMESPACE" --ignore-not-found=true &>/dev/null
}

# Function to provide next steps
provide_next_steps() {
    echo ""
    print_status "info" "Next Steps:"
    echo ""
    echo "1. Monitor Harness delegate pods:"
    echo "   oc get pods -n $NAMESPACE -w"
    echo ""
    echo "2. Check pod events if issues persist:"
    echo "   oc describe pod <pod-name> -n $NAMESPACE"
    echo ""
    echo "3. Test ECR connectivity manually:"
    echo "   aws ecr get-login-password --region $REGION --profile $AWS_PROFILE"
    echo ""
    echo "4. If problems continue, check the comprehensive troubleshooting guide:"
    echo "   cat comprehensive-harness-delegate-troubleshooting.md"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    echo ""
    
    diagnose_issue
    echo ""
    
    find_vpc_info
    echo ""
    
    check_route_tables
    echo ""
    
    find_nat_gateway
    echo ""
    
    if apply_fix; then
        echo ""
        test_fix
        echo ""
        provide_next_steps
        
        print_status "success" "Quick fix completed! Monitor your pods for improvement."
    else
        print_status "error" "Quick fix failed. Please check the comprehensive troubleshooting guide."
        exit 1
    fi
}

# Run main function
main "$@"
