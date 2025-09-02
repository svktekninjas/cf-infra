#!/bin/bash

# =============================================================================
# Comprehensive Network Troubleshooting Script
# =============================================================================

echo "🔍 Comprehensive Network Troubleshooting"
echo "========================================"

VPC_ID="vpc-075da49e833c3ce06"
PRIVATE_SUBNET="subnet-047f01550dcf5592f"
PUBLIC_SUBNET="subnet-081b7446060a163f1"
NAT_GATEWAY="nat-01d1f2b5f9a3b8d14"
ROUTE_TABLE_PRIVATE="rtb-02eb0e56a2969fb0a"
ROUTE_TABLE_PUBLIC="rtb-0522dff15ded6d4c2"
NACL="acl-03c8b41e3a5bcd268"
IGW="igw-013123a2547e17861"
AWS_PROFILE="sid-KS"

echo "Configuration:"
echo "VPC: $VPC_ID"
echo "Private Subnet: $PRIVATE_SUBNET"
echo "NAT Gateway: $NAT_GATEWAY"
echo ""

echo "=== 1. Checking NAT Gateway Health ==="
aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GATEWAY --profile $AWS_PROFILE --query 'NatGateways[0].[State,SubnetId,VpcId,ConnectivityType]' --output table

echo ""
echo "=== 2. Checking NAT Gateway Network Interfaces ==="
NAT_ENI=$(aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GATEWAY --profile $AWS_PROFILE --query 'NatGateways[0].NatGatewayAddresses[0].NetworkInterfaceId' --output text)
echo "NAT Gateway ENI: $NAT_ENI"
aws ec2 describe-network-interfaces --network-interface-ids $NAT_ENI --profile $AWS_PROFILE --query 'NetworkInterfaces[0].[Status,PrivateIpAddress,Association.PublicIp]' --output table

echo ""
echo "=== 3. Checking Route Table Associations ==="
echo "Private Route Table Associations:"
aws ec2 describe-route-tables --route-table-ids $ROUTE_TABLE_PRIVATE --profile $AWS_PROFILE --query 'RouteTables[0].Associations[*].[SubnetId,Main]' --output table

echo ""
echo "=== 4. Checking Internet Gateway Attachment ==="
aws ec2 describe-internet-gateways --internet-gateway-ids $IGW --profile $AWS_PROFILE --query 'InternetGateways[0].Attachments[*].[VpcId,State]' --output table

echo ""
echo "=== 5. Checking Security Group Rules for Worker Nodes ==="
# Find instances in private subnet
INSTANCES=$(aws ec2 describe-instances --filters "Name=subnet-id,Values=$PRIVATE_SUBNET" "Name=instance-state-name,Values=running" --profile $AWS_PROFILE --query 'Reservations[*].Instances[*].InstanceId' --output text)
echo "Instances in private subnet: $INSTANCES"

if [ "$INSTANCES" != "" ]; then
    FIRST_INSTANCE=$(echo $INSTANCES | awk '{print $1}')
    echo "Checking security groups for instance: $FIRST_INSTANCE"
    SG_IDS=$(aws ec2 describe-instances --instance-ids $FIRST_INSTANCE --profile $AWS_PROFILE --query 'Reservations[0].Instances[0].SecurityGroups[*].GroupId' --output text)
    echo "Security Groups: $SG_IDS"
    
    for sg in $SG_IDS; do
        echo "Checking egress rules for SG: $sg"
        aws ec2 describe-security-groups --group-ids $sg --profile $AWS_PROFILE --query 'SecurityGroups[0].IpPermissionsEgress[*].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp]' --output table
    done
fi

echo ""
echo "=== 6. Testing Route Propagation ==="
echo "Routes in private route table:"
aws ec2 describe-route-tables --route-table-ids $ROUTE_TABLE_PRIVATE --profile $AWS_PROFILE --query 'RouteTables[0].Routes[*].[DestinationCidrBlock,GatewayId,NatGatewayId,State]' --output table

echo ""
echo "=== 7. Checking VPC Flow Logs (if enabled) ==="
FLOW_LOGS=$(aws ec2 describe-flow-logs --filter "Name=resource-id,Values=$VPC_ID" --profile $AWS_PROFILE --query 'FlowLogs[*].[FlowLogId,FlowLogStatus,TrafficType]' --output table 2>/dev/null)
if [ "$FLOW_LOGS" != "" ]; then
    echo "$FLOW_LOGS"
else
    echo "No VPC Flow Logs found"
fi

echo ""
echo "=== 8. Checking VPC Endpoints ==="
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" --profile $AWS_PROFILE --query 'VpcEndpoints[*].[ServiceName,State,VpcEndpointType]' --output table

echo ""
echo "=== 9. Network Troubleshooting Summary ==="
echo "✅ Items to verify:"
echo "1. NAT Gateway should be 'available' and in public subnet"
echo "2. NAT Gateway ENI should have public IP"
echo "3. Private route table should route 0.0.0.0/0 to NAT Gateway"
echo "4. Internet Gateway should be 'available' and attached to VPC"
echo "5. Security groups should allow outbound HTTPS (port 443)"
echo "6. No conflicting routes or network ACL rules"

echo ""
echo "=== 10. Safe Fixes to Try ==="
echo "If issues found:"
echo "- Fix route table entries (safe)"
echo "- Update security group rules (safe)"
echo "- Restart NAT Gateway (moderate risk)"
echo "- Create new NAT Gateway (safe, costs money)"
echo ""
echo "⚠️  DO NOT:"
echo "- Delete NACL (will break entire VPC)"
echo "- Delete Internet Gateway (will break public access)"
echo "- Delete VPC (will destroy everything)"

