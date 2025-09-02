#!/bin/bash

echo "🌐 Network Troubleshooting Script for ROSA Cluster"
echo "=================================================="

# Check if logged into cluster
if ! oc whoami &>/dev/null; then
    echo "❌ Not logged into OpenShift cluster"
    exit 1
fi

echo "✅ Connected to cluster as: $(oc whoami)"
echo ""

# Get cluster info
CLUSTER_NAME="rosa-cluster-dev"
echo "1. Getting cluster network information..."
echo "Cluster: $CLUSTER_NAME"

# Get VPC and subnet information
echo ""
echo "2. Checking AWS VPC configuration..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*$CLUSTER_NAME*" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
if [ "$VPC_ID" != "None" ] && [ "$VPC_ID" != "" ]; then
    echo "VPC ID: $VPC_ID"
    
    # Check subnets
    echo ""
    echo "3. Checking subnets..."
    aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' --output table
    
    # Check route tables
    echo ""
    echo "4. Checking route tables..."
    aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[*].Routes[*].[DestinationCidrBlock,GatewayId,State]' --output table
    
    # Check security groups
    echo ""
    echo "5. Checking security groups..."
    aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=*worker*" --query 'SecurityGroups[*].[GroupId,GroupName,Description]' --output table
    
    # Check NAT gateways
    echo ""
    echo "6. Checking NAT gateways..."
    aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[*].[NatGatewayId,State,SubnetId]' --output table
    
    # Check internet gateways
    echo ""
    echo "7. Checking internet gateways..."
    aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[*].[InternetGatewayId,State]' --output table
else
    echo "⚠️  Could not find VPC for cluster $CLUSTER_NAME"
fi

echo ""
echo "8. Testing connectivity from cluster nodes..."

# Create a network test pod
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: network-test-pod
  namespace: default
spec:
  containers:
  - name: test
    image: registry.redhat.io/ubi8/ubi:latest
    command: ['sleep', '300']
  restartPolicy: Never
EOF

echo "Waiting for network test pod..."
oc wait --for=condition=Ready pod/network-test-pod -n default --timeout=60s

if [ $? -eq 0 ]; then
    echo "✅ Test pod ready"
    echo ""
    
    echo "9. DNS Resolution Tests..."
    echo "Testing ECR endpoint DNS:"
    oc exec network-test-pod -n default -- nslookup 818140567777.dkr.ecr.us-east-1.amazonaws.com
    echo ""
    
    echo "Testing Google DNS:"
    oc exec network-test-pod -n default -- nslookup google.com
    echo ""
    
    echo "10. Connectivity Tests..."
    echo "Testing ECR HTTPS connectivity:"
    oc exec network-test-pod -n default -- curl -v -I https://818140567777.dkr.ecr.us-east-1.amazonaws.com/v2/ --max-time 10
    echo ""
    
    echo "Testing general internet (Google):"
    oc exec network-test-pod -n default -- curl -I https://www.google.com --max-time 10
    echo ""
    
    echo "Testing AWS API connectivity:"
    oc exec network-test-pod -n default -- curl -I https://ec2.us-east-1.amazonaws.com --max-time 10
    echo ""
    
    echo "11. Network Configuration..."
    echo "IP configuration:"
    oc exec network-test-pod -n default -- ip addr show
    echo ""
    
    echo "Routing table:"
    oc exec network-test-pod -n default -- ip route
    echo ""
    
    echo "DNS configuration:"
    oc exec network-test-pod -n default -- cat /etc/resolv.conf
    echo ""
    
    # Cleanup
    oc delete pod network-test-pod -n default
else
    echo "❌ Test pod failed to start"
fi

echo ""
echo "12. Checking cluster network policies..."
oc get networkpolicies --all-namespaces

echo ""
echo "13. Checking cluster DNS..."
oc get pods -n openshift-dns

echo ""
echo "🔍 Network troubleshooting complete!"
echo ""
echo "Common issues and solutions:"
echo "- DNS failures: Check CoreDNS pods and VPC DNS settings"
echo "- Timeout errors: Check security groups, NACLs, and routing"
echo "- No internet: Check NAT gateway and internet gateway"
echo "- ECR specific: Check IAM roles and ECR permissions"
