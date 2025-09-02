#!/bin/bash

# =============================================================================
# Cluster Network Fix Script
# =============================================================================

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Load environment-specific config if specified
if [[ -n "$1" ]]; then
    load_environment_config "$1"
fi

echo "🔧 Cluster Network Fix Script"
echo "============================="

# Validate configuration
if ! validate_config; then
    echo "❌ Configuration validation failed"
    exit 1
fi

# Specific VPC and profile information
VPC_ID="vpc-075da49e833c3ce06"
AWS_PROFILE="sid-KS"

# Get current cluster info from oc connection
CURRENT_API_URL=$(oc whoami --show-server 2>/dev/null)
CURRENT_USER=$(oc whoami 2>/dev/null)

echo "Current Cluster: $CURRENT_API_URL"
echo "Current User: $CURRENT_USER"
echo "Region: $AWS_REGION"
echo "VPC ID: $VPC_ID"
echo "AWS Profile: $AWS_PROFILE"
echo ""

# Check AWS CLI access with profile
if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &>/dev/null; then
    echo "❌ AWS CLI not configured for profile: $AWS_PROFILE"
    exit 1
fi

# Check cluster connection
if [ "$CURRENT_API_URL" = "" ] || [ "$CURRENT_USER" = "" ]; then
    echo "❌ Not logged into OpenShift cluster"
    echo "Please login first"
    exit 1
fi

echo "✅ Connected to cluster as: $CURRENT_USER"
echo "✅ Using VPC: $VPC_ID"
echo ""

echo "1. Checking security groups in VPC..."
# Find security groups associated with the VPC
SECURITY_GROUPS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[*].GroupId' --output text --profile "$AWS_PROFILE")

echo "Found security groups: $SECURITY_GROUPS"

for sg in $SECURITY_GROUPS; do
    echo "Checking security group: $sg"
    
    # Get security group name for context
    SG_NAME=$(aws ec2 describe-security-groups --group-ids $sg --query 'SecurityGroups[0].GroupName' --output text --profile "$AWS_PROFILE")
    echo "  Name: $SG_NAME"
    
    # Check if HTTPS outbound rule exists
    HTTPS_RULE=$(aws ec2 describe-security-groups --group-ids $sg \
        --query 'SecurityGroups[0].EgressRules[?FromPort==`443` && ToPort==`443` && IpProtocol==`tcp`]' --output text --profile "$AWS_PROFILE" 2>/dev/null)
    
    if [ "$HTTPS_RULE" = "" ]; then
        echo "  ⚠️  No HTTPS outbound rule found. Adding..."
        aws ec2 authorize-security-group-egress \
            --group-id $sg \
            --protocol tcp \
            --port 443 \
            --cidr 0.0.0.0/0 \
            --profile "$AWS_PROFILE" 2>/dev/null && echo "  ✅ HTTPS outbound rule added" || echo "  ⚠️  Could not add rule (may already exist or no permissions)"
    else
        echo "  ✅ HTTPS outbound rule exists"
    fi
    
    # Check for all traffic outbound rule
    ALL_TRAFFIC=$(aws ec2 describe-security-groups --group-ids $sg \
        --query 'SecurityGroups[0].EgressRules[?IpProtocol==`-1`]' --output text --profile "$AWS_PROFILE" 2>/dev/null)
    
    if [ "$ALL_TRAFFIC" != "" ]; then
        echo "  ✅ All traffic outbound rule exists"
    fi
done

echo ""
echo "2. Checking subnets and routing..."
# Get private subnets in the VPC
PRIVATE_SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=map-public-ip-on-launch,Values=false" \
    --query 'Subnets[*].SubnetId' --output text --profile "$AWS_PROFILE")

echo "Private subnets: $PRIVATE_SUBNETS"

# Check each private subnet has route to NAT gateway
for subnet in $PRIVATE_SUBNETS; do
    echo "Checking routing for subnet: $subnet"
    
    # Get route table for this subnet
    ROUTE_TABLE=$(aws ec2 describe-route-tables \
        --filters "Name=association.subnet-id,Values=$subnet" \
        --query 'RouteTables[0].RouteTableId' --output text --profile "$AWS_PROFILE")
    
    if [ "$ROUTE_TABLE" != "None" ] && [ "$ROUTE_TABLE" != "" ]; then
        echo "  Route table: $ROUTE_TABLE"
        
        # Check for NAT gateway route
        NAT_ROUTE=$(aws ec2 describe-route-tables --route-table-ids $ROUTE_TABLE \
            --query 'RouteTables[0].Routes[?GatewayId!=null && starts_with(GatewayId, `nat-`)]' --output text --profile "$AWS_PROFILE")
        
        if [ "$NAT_ROUTE" != "" ]; then
            echo "  ✅ NAT gateway route exists"
        else
            echo "  ⚠️  No NAT gateway route found"
            echo "  This may cause internet connectivity issues"
        fi
        
        # Show all routes for debugging
        echo "  Routes in route table:"
        aws ec2 describe-route-tables --route-table-ids $ROUTE_TABLE \
            --query 'RouteTables[0].Routes[*].[DestinationCidrBlock,GatewayId,State]' --output table --profile "$AWS_PROFILE"
    else
        echo "  ⚠️  Could not find route table for subnet"
    fi
done

echo ""
echo "3. Checking NAT gateways..."
NAT_GATEWAYS=$(aws ec2 describe-nat-gateways \
    --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
    --query 'NatGateways[*].[NatGatewayId,State,SubnetId]' --output table --profile "$AWS_PROFILE")

if [ "$NAT_GATEWAYS" != "" ]; then
    echo "$NAT_GATEWAYS"
else
    echo "⚠️  No NAT gateways found in VPC"
    echo "This will cause connectivity issues for private subnets"
fi

echo ""
echo "4. Checking internet gateway..."
IGW=$(aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query 'InternetGateways[0].[InternetGatewayId,State]' --output table --profile "$AWS_PROFILE")

if [ "$IGW" != "" ]; then
    echo "$IGW"
else
    echo "⚠️  No internet gateway found"
fi

echo ""
echo "5. Testing ECR endpoint resolution..."
nslookup $ECR_REGISTRY || echo "DNS resolution may have issues"

echo ""
echo "6. Checking/Creating ECR VPC endpoints..."
# Check if ECR VPC endpoint exists
ECR_DKR_ENDPOINT=$(aws ec2 describe-vpc-endpoints \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=service-name,Values=com.amazonaws.$AWS_REGION.ecr.dkr" \
    --query 'VpcEndpoints[0].VpcEndpointId' --output text --profile "$AWS_PROFILE")

ECR_API_ENDPOINT=$(aws ec2 describe-vpc-endpoints \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=service-name,Values=com.amazonaws.$AWS_REGION.ecr.api" \
    --query 'VpcEndpoints[0].VpcEndpointId' --output text --profile "$AWS_PROFILE")

if [ "$ECR_DKR_ENDPOINT" = "None" ] || [ "$ECR_DKR_ENDPOINT" = "" ]; then
    echo "⚠️  No ECR DKR VPC endpoint found. Attempting to create one..."
    
    # Get private subnet IDs for endpoint
    SUBNET_IDS=$(echo $PRIVATE_SUBNETS | tr ' ' ',')
    
    # Get a security group that allows HTTPS
    DEFAULT_SG=$(echo $SECURITY_GROUPS | awk '{print $1}')
    
    if [ "$SUBNET_IDS" != "" ] && [ "$DEFAULT_SG" != "" ]; then
        # Create ECR DKR endpoint
        aws ec2 create-vpc-endpoint \
            --vpc-id $VPC_ID \
            --service-name com.amazonaws.$AWS_REGION.ecr.dkr \
            --vpc-endpoint-type Interface \
            --subnet-ids $SUBNET_IDS \
            --security-group-ids $DEFAULT_SG \
            --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=ECR-DKR-Endpoint}]" \
            --profile "$AWS_PROFILE" && echo "✅ ECR DKR endpoint created" || echo "⚠️  Could not create ECR DKR endpoint"
        
        # Create ECR API endpoint
        aws ec2 create-vpc-endpoint \
            --vpc-id $VPC_ID \
            --service-name com.amazonaws.$AWS_REGION.ecr.api \
            --vpc-endpoint-type Interface \
            --subnet-ids $SUBNET_IDS \
            --security-group-ids $DEFAULT_SG \
            --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=ECR-API-Endpoint}]" \
            --profile "$AWS_PROFILE" && echo "✅ ECR API endpoint created" || echo "⚠️  Could not create ECR API endpoint"
        
        # Create S3 gateway endpoint for ECR layers
        aws ec2 create-vpc-endpoint \
            --vpc-id $VPC_ID \
            --service-name com.amazonaws.$AWS_REGION.s3 \
            --vpc-endpoint-type Gateway \
            --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=S3-Gateway-Endpoint}]" \
            --profile "$AWS_PROFILE" && echo "✅ S3 gateway endpoint created" || echo "⚠️  Could not create S3 gateway endpoint"
        
    else
        echo "⚠️  Could not create VPC endpoints - missing subnet or security group info"
    fi
else
    echo "✅ ECR DKR VPC endpoint already exists: $ECR_DKR_ENDPOINT"
fi

if [ "$ECR_API_ENDPOINT" = "None" ] || [ "$ECR_API_ENDPOINT" = "" ]; then
    echo "⚠️  ECR API endpoint missing (may have been created above)"
else
    echo "✅ ECR API VPC endpoint already exists: $ECR_API_ENDPOINT"
fi

echo ""
echo "🎯 Network fix complete!"
echo ""
echo "Summary of changes:"
echo "- VPC identified: $VPC_ID"
echo "- Security groups checked for HTTPS outbound"
echo "- NAT gateway routing verified"
echo "- ECR VPC endpoints checked/created"
echo ""
echo "If connectivity issues persist:"
echo "1. Check that NAT gateways exist and have proper routing"
echo "2. Verify security groups allow outbound HTTPS (port 443)"
echo "3. Ensure internet gateway is properly attached"
echo "4. Wait 2-3 minutes for VPC endpoints to become available"
echo ""
echo "Test connectivity with:"
echo "oc run test-pod --image=curlimages/curl --rm -it -- curl -I https://$ECR_REGISTRY/v2/"
