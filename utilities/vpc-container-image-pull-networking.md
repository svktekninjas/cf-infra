# 🌐 VPC Network Settings for Container Image Pulls

## 📋 **Overview**
When pulling container images to workloads in a VPC (same region), you need proper outbound internet connectivity. Here are the default network settings required.

## 🏗️ **Required Network Components**

### **1. VPC Configuration**
```
VPC CIDR: 10.0.0.0/16 (or your preferred range)
DNS Resolution: Enabled
DNS Hostnames: Enabled
```

### **2. Subnet Configuration**

#### **Private Subnets (for workloads):**
```
Private Subnet 1: 10.0.1.0/24 (AZ-a)
Private Subnet 2: 10.0.2.0/24 (AZ-b)
Auto-assign Public IP: Disabled
```

#### **Public Subnets (for NAT Gateway):**
```
Public Subnet 1: 10.0.101.0/24 (AZ-a)  
Public Subnet 2: 10.0.102.0/24 (AZ-b)
Auto-assign Public IP: Enabled
```

### **3. Internet Gateway (IGW)**
```
Internet Gateway: Attached to VPC
Purpose: Provides internet access to public subnets
```

### **4. NAT Gateway**
```
NAT Gateway: Deployed in public subnet
Elastic IP: Attached
Purpose: Provides outbound internet access for private subnets
```

### **5. Route Tables**

#### **Public Route Table:**
```
Destination: 10.0.0.0/16 → Target: Local
Destination: 0.0.0.0/0   → Target: Internet Gateway
Associated with: Public subnets
```

#### **Private Route Table:**
```
Destination: 10.0.0.0/16 → Target: Local  
Destination: 0.0.0.0/0   → Target: NAT Gateway
Associated with: Private subnets
```

### **6. Security Groups**

#### **Default Security Group (for workloads):**
```
Inbound Rules:
- Type: All Traffic, Source: Same Security Group (self-reference)

Outbound Rules:  
- Type: All Traffic, Destination: 0.0.0.0/0 (CRITICAL for image pulls)
```

### **7. Network ACLs (NACLs)**

#### **Default NACL (recommended):**
```
Inbound Rules:
- Rule 100: All Traffic, Source: 0.0.0.0/0, Action: ALLOW

Outbound Rules:
- Rule 100: All Traffic, Destination: 0.0.0.0/0, Action: ALLOW
```

## 🎯 **Critical Settings for Container Image Pulls**

### **✅ Must Have:**

1. **Outbound HTTPS (443) Access**
   ```
   Security Group Egress: 0.0.0.0/0:443 (HTTPS)
   NACL Outbound: 0.0.0.0/0:443 (HTTPS)
   ```

2. **DNS Resolution**
   ```
   Security Group Egress: 0.0.0.0/0:53 (DNS)
   VPC DNS Resolution: Enabled
   VPC DNS Hostnames: Enabled
   ```

3. **Ephemeral Ports (for return traffic)**
   ```
   NACL Inbound: 0.0.0.0/0:1024-65535 (Ephemeral ports)
   ```

### **🌐 Container Registry Endpoints:**

#### **Docker Hub:**
```
registry-1.docker.io:443
auth.docker.io:443
production.cloudflare.docker.com:443
```

#### **Amazon ECR (same region):**
```
<account-id>.dkr.ecr.<region>.amazonaws.com:443
<account-id>.dkr.ecr.<region>.amazonaws.com:443
```

#### **Other Registries:**
```
gcr.io:443 (Google Container Registry)
quay.io:443 (Red Hat Quay)
ghcr.io:443 (GitHub Container Registry)
```

## 🔧 **Troubleshooting Network Issues**

### **Common Problems:**

1. **Missing NAT Gateway Route**
   ```bash
   # Check private route table
   aws ec2 describe-route-tables --route-table-ids rtb-xxx
   
   # Should have: 0.0.0.0/0 → nat-xxx
   ```

2. **Restrictive Security Groups**
   ```bash
   # Check outbound rules
   aws ec2 describe-security-groups --group-ids sg-xxx
   
   # Should allow: 0.0.0.0/0:443 (HTTPS)
   ```

3. **Restrictive NACLs**
   ```bash
   # Check NACL rules
   aws ec2 describe-network-acls --network-acl-ids acl-xxx
   
   # Should allow outbound HTTPS and inbound ephemeral ports
   ```

### **Testing Connectivity:**

```bash
# Test from EC2 instance in private subnet
curl -I https://registry-1.docker.io/v2/
curl -I https://818140567777.dkr.ecr.us-east-1.amazonaws.com/v2/

# Should return HTTP 200 or 401 (not timeout)
```

## 🚀 **VPC Endpoints (Optional but Recommended)**

### **For ECR (reduces NAT Gateway costs):**
```
VPC Endpoint: com.amazonaws.region.ecr.dkr
VPC Endpoint: com.amazonaws.region.ecr.api  
VPC Endpoint: com.amazonaws.region.s3 (Gateway endpoint)
```

### **Benefits:**
- Reduced NAT Gateway data transfer costs
- Improved performance (stays within AWS network)
- Enhanced security (traffic doesn't leave AWS)

## 📊 **Default AWS Settings Summary**

### **✅ What AWS Provides by Default:**
- VPC with DNS resolution enabled
- Default security group with outbound 0.0.0.0/0 access
- Default NACL with allow-all rules
- Ability to create IGW and NAT Gateway

### **❌ What You Must Configure:**
- Internet Gateway attachment
- NAT Gateway creation and placement
- Route table associations
- Proper subnet routing (0.0.0.0/0 → NAT Gateway)

## 🎯 **Minimal Working Configuration**

For container image pulls, you need **at minimum**:

1. **Private subnet** with workloads
2. **Public subnet** with NAT Gateway  
3. **Internet Gateway** attached to VPC
4. **Route**: Private subnet → NAT Gateway → Internet Gateway
5. **Security Group**: Allow outbound HTTPS (443)
6. **DNS**: VPC DNS resolution enabled

## 🔍 **Quick Validation Checklist**

```bash
# 1. Check VPC DNS settings
aws ec2 describe-vpcs --vpc-ids vpc-xxx --query 'Vpcs[0].[EnableDnsSupport,EnableDnsHostnames]'

# 2. Check NAT Gateway
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=vpc-xxx"

# 3. Check routes
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxx"

# 4. Check security groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-xxx"

# 5. Test connectivity
curl -I --connect-timeout 10 https://registry-1.docker.io/v2/
```

---

**Key Takeaway**: The most common issue is missing or incorrect routing from private subnets to NAT Gateway. Ensure your private route table has `0.0.0.0/0 → NAT Gateway` route! 🎯
