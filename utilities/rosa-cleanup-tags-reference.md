# 🚀 ROSA Cleanup Ansible Playbook Tags Reference

## 📋 **Available Tags for ROSA Cleanup**

### **🏷️ Main Tags (cluster_cleanup_simple.yml):**

All tasks in the ROSA cleanup use these two main tags:

- **`cluster-cleanup`** - All cluster-related cleanup operations
- **`cleanup`** - General cleanup operations (same as cluster-cleanup)

### **📝 Usage Examples:**

```bash
cd /Users/swaroop/SIDKS/ansible

# Run complete ROSA cleanup
ansible-playbook playbooks/cleanup_cluster.yml \
  -e target_environment=dev \
  -e aws_profile=sid-KS \
  --tags cluster-cleanup

# Same as above (cleanup is alias for cluster-cleanup)
ansible-playbook playbooks/cleanup_cluster.yml \
  -e target_environment=dev \
  -e aws_profile=sid-KS \
  --tags cleanup

# Skip confirmation prompt (dangerous!)
ansible-playbook playbooks/cleanup_cluster.yml \
  -e target_environment=dev \
  -e aws_profile=sid-KS \
  -e confirmation_user_input=DELETE \
  --tags cleanup
```

## 🔧 **Cleanup Operations Performed (in order):**

### **1. Pre-cleanup Validation**
- Load environment configuration
- Set cleanup variables
- Display cleanup configuration
- **Confirmation prompt** (requires typing "DELETE")

### **2. ROSA Cluster Deletion**
```bash
rosa delete cluster -c rosa-cluster-dev --region us-east-1 --yes
```

### **3. AWS Resource Cleanup (by category):**

#### **Elastic IPs:**
- Release EIPs from EC2 instances
- Release tagged EIPs
- Note NAT Gateway EIPs for later cleanup

#### **EC2 Instances:**
- Terminate instances with app tag
- Wait for termination completion

#### **Load Balancers:**
- Delete Application Load Balancers
- Delete Network Load Balancers
- Delete Classic Load Balancers

#### **NAT Gateways:**
- Delete NAT Gateways in VPC
- Release associated Elastic IPs

#### **Network Interfaces:**
- Delete unattached ENIs
- Clean up orphaned network interfaces

#### **Security Groups:**
- Delete non-default security groups
- Handle dependency cleanup

#### **EBS Volumes:**
- Delete available EBS volumes
- Clean up snapshots

#### **Subnets:**
- Delete subnets (if delete_cluster_vpc=true)

#### **Route Tables:**
- Delete custom route tables (if delete_cluster_vpc=true)

#### **VPC:**
- Delete VPC (if delete_cluster_vpc=true)

#### **IAM Resources:**
- Clean up ROSA operator roles
- Remove OIDC providers

## 🎯 **Specialized Cleanup Commands:**

### **ROSA-Only Cleanup (no AWS resources):**
```bash
# Just delete the ROSA cluster
rosa delete cluster --cluster=rosa-cluster-dev --profile sid-KS --yes

# Clean up remaining ROSA resources
rosa delete operator-roles --prefix rosa-cluster-dev-e7o9 --profile sid-KS --yes
rosa delete oidc-provider --oidc-config-id 2g2gqvov44esri8v9t7r6p83umfoc71l --profile sid-KS --yes
```

### **AWS Resources Only (after ROSA deletion):**
```bash
# Use the completion script
./utilities/complete-rosa-cleanup.sh

# Or run specific cleanup phases
ansible-playbook playbooks/cleanup_cluster.yml \
  -e target_environment=dev \
  -e aws_profile=sid-KS \
  -e skip_rosa_deletion=true \
  --tags cleanup
```

## ⚠️ **Important Variables:**

### **Required Variables:**
- `target_environment` - Environment to clean up (dev/test/prod)
- `aws_profile` - AWS profile to use

### **Optional Variables:**
- `delete_cluster_vpc=true` - Delete VPC and all networking (default: false)
- `confirmation_user_input=DELETE` - Skip confirmation prompt
- `cleanup_region` - AWS region (default: us-east-1)

### **Safety Variables:**
- `app_tag_key` - Tag used to identify resources (default: app-{environment})
- `cluster_name` - Specific cluster name to delete

## 🚨 **Safety Features:**

1. **Confirmation Required** - Must type "DELETE" to proceed
2. **Tag-Based Cleanup** - Only deletes resources with specific tags
3. **Error Handling** - Continues even if some resources don't exist
4. **VPC Protection** - VPC deletion disabled by default
5. **Wait Conditions** - Ensures proper deletion order

## 📊 **Monitoring Cleanup Progress:**

```bash
# Check ROSA cluster status
rosa list clusters --profile sid-KS

# Check EC2 instances
aws ec2 describe-instances --region us-east-1 --profile sid-KS \
  --query 'Reservations[*].Instances[?State.Name==`running`].InstanceId' --output text

# Check load balancers
aws elbv2 describe-load-balancers --region us-east-1 --profile sid-KS \
  --query 'LoadBalancers[*].LoadBalancerName' --output text

# Check NAT Gateways
aws ec2 describe-nat-gateways --region us-east-1 --profile sid-KS \
  --query 'NatGateways[?State==`available`].NatGatewayId' --output text
```

## 🎯 **Quick Commands Summary:**

```bash
# Complete cleanup with confirmation
ansible-playbook playbooks/cleanup_cluster.yml -e target_environment=dev -e aws_profile=sid-KS --tags cleanup

# Complete cleanup without confirmation (DANGEROUS!)
ansible-playbook playbooks/cleanup_cluster.yml -e target_environment=dev -e aws_profile=sid-KS -e confirmation_user_input=DELETE --tags cleanup

# Complete cleanup including VPC deletion
ansible-playbook playbooks/cleanup_cluster.yml -e target_environment=dev -e aws_profile=sid-KS -e delete_cluster_vpc=true --tags cleanup

# Just the ROSA cluster (manual)
rosa delete cluster --cluster=rosa-cluster-dev --profile sid-KS --yes

# Complete remaining cleanup
./utilities/complete-rosa-cleanup.sh
```

---

**Note**: The ROSA cleanup playbook uses only two main tags (`cluster-cleanup` and `cleanup`) because all operations are interdependent and should be run together for complete cleanup. Individual resource cleanup is handled through the comprehensive script logic rather than separate tags.
