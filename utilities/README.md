# Ansible Utilities for Harness Delegate Troubleshooting

This directory contains comprehensive troubleshooting and utility scripts for CF Harness deployment on ROSA clusters, with **dynamic cluster endpoint detection** and full IAM/RBAC support.

## 🎯 Quick Start

### Get Current Cluster Information
```bash
cd /Users/swaroop/SIDKS/ansible/utilities
./cluster-manager.sh
# Select option 10 (Complete cluster setup guide)
```

### Login to Cluster
```bash
./get-cluster-login.sh
# Automatically detects current cluster endpoints
```

### Troubleshoot Issues
```bash
./master-troubleshoot.sh
# Select option 11 for complete fix
```

## 📋 Scripts Overview

### 🏗️ **Cluster Management** (NEW)
1. **`cluster-manager.sh`** - Complete cluster management menu
   - List clusters, get details, login instructions
   - Update cluster info files dynamically
   - Test connectivity and verify connections

2. **`get-cluster-login.sh`** - Smart login helper
   - Automatically gets current cluster endpoints
   - Provides multiple login methods
   - Verifies connection status

3. **`cluster-utils.sh`** - Dynamic utility functions
   - `get_cluster_api_url()` - Get current API endpoint
   - `get_cluster_console_url()` - Get web console URL
   - `check_cluster_login()` - Verify correct cluster connection
   - `update_cluster_info()` - Update info files

### 🎯 **Master Script**
4. **`master-troubleshoot.sh`** - Enhanced interactive menu
   - Dynamic cluster endpoint detection
   - Comprehensive diagnostics and fixes
   - Cluster management integration

### 🔍 **Diagnostic Scripts**
5. **`troubleshoot-ecr-connectivity.sh`** - ECR connectivity diagnostics
6. **`troubleshoot-network.sh`** - Network and VPC diagnostics  
7. **`troubleshoot-iam-permissions.sh`** - IAM and ROSA permissions check

### 🔧 **Fix Scripts**
8. **`fix-ecr-authentication.sh`** - ECR authentication setup
9. **`fix-rosa-networking.sh`** - ROSA network configuration
10. **`fix-iam-permissions.sh`** - IAM permissions setup
11. **`fix-rosa-rbac.sh`** - ROSA RBAC configuration
12. **`setup-irsa-roles.sh`** - IRSA setup

### 🚀 **Installation**
13. **`install-harness-delegate.sh`** - Harness delegate installation

## ✨ Key Features

### 🔄 **Dynamic Cluster Detection**
- ✅ No hardcoded endpoints - all scripts detect current cluster information
- ✅ Automatic API URL discovery from `rosa describe cluster`
- ✅ Real-time cluster state checking
- ✅ Smart connection verification

### 🔐 **Comprehensive IAM & RBAC**
- ✅ AWS IAM policies and cross-account access validation
- ✅ ROSA cluster IAM roles analysis (image-registry, worker, operator roles)
- ✅ OpenShift RBAC permissions and security contexts
- ✅ IRSA (IAM Roles for Service Accounts) configuration
- ✅ Cross-account ECR access (818140567777 ↔ 606639739464)

### 🌐 **Network Diagnostics**
- ✅ VPC, security groups, and routing validation
- ✅ ECR connectivity testing from cluster nodes
- ✅ NAT gateway and internet gateway verification
- ✅ VPC endpoints creation for private ECR access

### 🎯 **Complete Automation**
- ✅ One-click complete fix (IAM + IRSA + Network + RBAC + Install)
- ✅ Intelligent error detection and resolution
- ✅ Comprehensive logging and status reporting

## 🚀 Usage Examples

### Complete Setup (Recommended)
```bash
# 1. Get cluster info and login
./cluster-manager.sh  # Option 10 (Complete setup guide)

# 2. Run complete fix
./master-troubleshoot.sh  # Option 11 (Complete fix)

# 3. Verify installation
oc get pods -n harness-delegate-ng
```

### Diagnostic Only
```bash
# Run all diagnostics
./master-troubleshoot.sh  # Option 10

# Or individual diagnostics
./troubleshoot-iam-permissions.sh
./troubleshoot-ecr-connectivity.sh
./troubleshoot-network.sh
```

### Cluster Management
```bash
# Interactive cluster management
./cluster-manager.sh

# Quick login help
./get-cluster-login.sh

# Update cluster info files
./cluster-manager.sh  # Option 5
```

## 📊 Cluster Information Management

### Automatic Updates
All cluster information is now retrieved dynamically:
- **API URLs**: Retrieved from `rosa describe cluster`
- **Console URLs**: Auto-detected for web access
- **OIDC Issuers**: For IRSA configuration
- **Cluster State**: Real-time status checking

### Updated Files
The scripts automatically update:
- `/Users/swaroop/SIDKS/ansible/environments/dev/cluster-info-dev.md`
- `/Users/swaroop/SIDKS/ansible/environments/dev/connect-dev.sh`
- All utility scripts use dynamic endpoints

## 🔧 Prerequisites

### Required Tools
- **ROSA CLI**: `rosa` command available
- **OpenShift CLI**: `oc` command available  
- **AWS CLI**: `aws` command configured

### Required Permissions
- **AWS IAM**: CreateRole, AttachRolePolicy, CreatePolicy, ECR access
- **OpenShift**: cluster-admin or equivalent permissions
- **ROSA**: Cluster management permissions

### Verification
```bash
# Check tools
rosa version
oc version
aws sts get-caller-identity

# Check cluster access
./cluster-manager.sh  # Option 4 (Check connection)
```

## 🚨 Common Issues Resolved

### ✅ ECR Image Pull Timeout
**Root Causes Addressed:**
- Network connectivity (security groups, NAT gateways)
- ECR authentication (image pull secrets, IRSA)
- IAM permissions (ECR policies, cross-account access)
- RBAC permissions (service accounts, cluster roles)

**Solution:**
```bash
./master-troubleshoot.sh  # Option 11 (Complete fix)
```

### ✅ Dynamic Endpoint Issues
**Before:** Scripts failed with hardcoded endpoints when clusters were recreated
**Now:** All endpoints detected dynamically from live cluster information

### ✅ Cross-Account ECR Access
**Handles:** Source account (818140567777) and target account (606639739464)
**Configures:** Repository policies, IAM roles, trust relationships

### ✅ IRSA Configuration
**Sets up:** IAM roles with OIDC trust policies for service accounts
**Supports:** Multiple namespaces and deployment scenarios

## 📚 Documentation

- **`CLUSTER_INSTRUCTIONS.md`** - Comprehensive cluster management guide
- **`README.md`** - This overview (you are here)
- Individual script help: `./script-name.sh --help`

## 🔗 Integration with Ansible

### Before Ansible Execution
```bash
# 1. Verify cluster connection
./cluster-manager.sh  # Option 4

# 2. Run diagnostics
./master-troubleshoot.sh  # Option 10

# 3. Fix any issues
./master-troubleshoot.sh  # Option 11
```

### Ansible Playbook Execution
```bash
cd /Users/swaroop/SIDKS/ansible
ansible-playbook playbooks/setup-harness.yml -e env=dev
```

### After Ansible Issues
```bash
# Troubleshoot specific problems
./master-troubleshoot.sh
# Select appropriate diagnostic/fix option
```

## 🎯 Advanced Features

### Multi-Cluster Support
```bash
# Works with any ROSA cluster
./cluster-manager.sh
# Enter different cluster name when prompted
```

### Environment Management
```bash
# Supports dev, test, prod environments
./cluster-manager.sh  # Option 5
# Specify environment when updating info files
```

### Comprehensive Logging
All scripts provide detailed logging:
- ✅ Step-by-step progress indicators
- ✅ Success/failure status for each operation
- ✅ Detailed error messages with resolution steps
- ✅ Summary reports with next steps

## 📞 Support

### Get Help
```bash
./cluster-manager.sh      # Interactive cluster management
./master-troubleshoot.sh  # Interactive troubleshooting
```

### Emergency Recovery
```bash
rosa list clusters                    # Find your cluster
./get-cluster-login.sh               # Get login instructions
./master-troubleshoot.sh             # Fix any issues
```

### Detailed Troubleshooting
See `CLUSTER_INSTRUCTIONS.md` for comprehensive troubleshooting guides.

---

This enhanced toolkit provides enterprise-grade troubleshooting with dynamic cluster detection, comprehensive IAM/RBAC support, and complete automation for Harness delegate deployment on ROSA clusters.
