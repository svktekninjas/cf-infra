# ROSA Cluster Management and Troubleshooting Instructions

This document provides comprehensive instructions for managing ROSA clusters and getting cluster details dynamically.

## 🎯 Quick Start

### Get Cluster Information
```bash
cd /Users/swaroop/SIDKS/ansible/utilities
./cluster-manager.sh
# Select option 10 (Complete cluster setup guide)
```

### Login to Cluster
```bash
./get-cluster-login.sh
# Follow the provided instructions
```

### Troubleshoot Issues
```bash
./master-troubleshoot.sh
# Select appropriate option based on your issue
```

## 📋 Available Scripts

### 🏗️ Cluster Management
- **`cluster-manager.sh`** - Complete cluster management menu
- **`get-cluster-login.sh`** - Get login instructions for any cluster
- **`cluster-utils.sh`** - Utility functions (sourced by other scripts)

### 🔍 Diagnostics
- **`troubleshoot-ecr-connectivity.sh`** - ECR connectivity issues
- **`troubleshoot-network.sh`** - Network and VPC issues
- **`troubleshoot-iam-permissions.sh`** - IAM and RBAC issues

### 🔧 Fixes
- **`fix-ecr-authentication.sh`** - ECR authentication setup
- **`fix-rosa-networking.sh`** - Network configuration
- **`fix-iam-permissions.sh`** - IAM policies and roles
- **`fix-rosa-rbac.sh`** - OpenShift RBAC setup
- **`setup-irsa-roles.sh`** - IAM Roles for Service Accounts

## 🔍 Getting Cluster Details

### Method 1: Using ROSA CLI Directly
```bash
# List all clusters
rosa list clusters

# Get detailed cluster information
rosa describe cluster -c rosa-cluster-dev

# Get admin credentials
rosa describe admin -c rosa-cluster-dev

# Create admin user if needed
rosa create admin -c rosa-cluster-dev
```

### Method 2: Using Our Cluster Manager
```bash
./cluster-manager.sh
# Select from menu options:
# 1. List all clusters
# 2. Get cluster details
# 6. Get admin credentials
# 9. Show cluster endpoints
```

### Method 3: Using Utility Functions
```bash
# Source the utilities
source ./cluster-utils.sh

# Get specific information
get_cluster_api_url "rosa-cluster-dev"
get_cluster_console_url "rosa-cluster-dev"
get_cluster_state "rosa-cluster-dev"
get_oidc_issuer "rosa-cluster-dev"
```

## 🔑 Login Methods

### Method 1: Direct CLI Login
```bash
# Get the API URL dynamically
API_URL=$(rosa describe cluster -c rosa-cluster-dev | grep "API URL:" | awk '{print $3}')

# Login with username/password
oc login $API_URL --username cluster-admin

# You'll be prompted for password - get it with:
rosa describe admin -c rosa-cluster-dev
```

### Method 2: Web Console Login
```bash
# Get console URL
CONSOLE_URL=$(rosa describe cluster -c rosa-cluster-dev | grep "Console URL:" | awk '{print $3}')

# Open in browser
open $CONSOLE_URL

# After login:
# 1. Click your username (top right)
# 2. Select "Copy login command"
# 3. Run the provided oc login command
```

### Method 3: Kubeconfig Download
```bash
# Download kubeconfig
rosa download kubeconfig -c rosa-cluster-dev

# This automatically configures kubectl/oc
```

### Method 4: Using Our Helper Script
```bash
./get-cluster-login.sh
# Follow the interactive instructions
```

## 🔍 Verifying Connection

### Check Current Connection
```bash
# Check if logged in
oc whoami

# Check which cluster
oc whoami --show-server

# Check permissions
oc auth can-i '*' '*' --all-namespaces
```

### Using Our Verification
```bash
# Check connection to specific cluster
source ./cluster-utils.sh
check_cluster_login "rosa-cluster-dev"
```

## 📊 Cluster Information Details

### Basic Information
```bash
rosa describe cluster -c rosa-cluster-dev
```

This provides:
- **Name**: Cluster name
- **State**: ready/installing/error
- **API URL**: OpenShift API endpoint
- **Console URL**: Web console URL
- **Version**: OpenShift version
- **Region**: AWS region
- **OIDC Endpoint**: For IRSA configuration

### Network Information
```bash
rosa describe cluster -c rosa-cluster-dev | grep -A 10 "Network:"
```

This shows:
- **Service CIDR**: Internal service network
- **Machine CIDR**: Node network
- **Pod CIDR**: Pod network
- **Host Prefix**: Subnet size

### IAM Roles
```bash
rosa describe cluster -c rosa-cluster-dev | grep "arn:aws:iam"
```

This lists:
- **Installer Role**: Cluster installation
- **Support Role**: Red Hat support access
- **Control Plane Role**: Master node permissions
- **Worker Role**: Worker node permissions
- **Operator Roles**: Service-specific roles

## 🔧 Dynamic Configuration Updates

### Update Cluster Info Files
```bash
./cluster-manager.sh
# Select option 5 (Update cluster info files)
```

This updates:
- `/Users/swaroop/SIDKS/ansible/environments/dev/cluster-info-dev.md`
- Connection scripts with current endpoints

### Update All Scripts
All utility scripts now dynamically get cluster information:
- No hardcoded endpoints
- Automatic cluster discovery
- Real-time cluster state checking

## 🚨 Troubleshooting Connection Issues

### Issue: Cluster Not Found
```bash
# Check available clusters
rosa list clusters

# Verify cluster name spelling
# Check AWS profile/region
aws configure list
```

### Issue: Authentication Failed
```bash
# Check admin user exists
rosa describe admin -c rosa-cluster-dev

# Create admin if needed
rosa create admin -c rosa-cluster-dev

# Try web console method
./cluster-manager.sh  # Option 3
```

### Issue: Wrong Cluster Connection
```bash
# Check current connection
oc whoami --show-server

# Get correct API URL
rosa describe cluster -c rosa-cluster-dev | grep "API URL"

# Login to correct cluster
oc login CORRECT_API_URL --username cluster-admin
```

### Issue: Cluster Not Ready
```bash
# Check cluster state
rosa describe cluster -c rosa-cluster-dev | grep "State:"

# Wait for ready state
# Check installation logs if stuck
rosa logs install -c rosa-cluster-dev
```

## 📝 Environment-Specific Configuration

### Development Environment
- **Cluster**: rosa-cluster-dev
- **Config File**: `/Users/swaroop/SIDKS/ansible/environments/dev/cluster-info-dev.md`
- **Connect Script**: `/Users/swaroop/SIDKS/ansible/environments/dev/connect-dev.sh`

### Production Environment
- **Cluster**: rosa-cluster-prod (if exists)
- **Config File**: `/Users/swaroop/SIDKS/ansible/environments/prod/cluster-info-prod.md`
- **Connect Script**: `/Users/swaroop/SIDKS/ansible/environments/prod/connect-prod.sh`

## 🎯 Best Practices

### 1. Always Verify Cluster State
```bash
# Before any operations
rosa describe cluster -c CLUSTER_NAME | grep "State:"
```

### 2. Use Dynamic Scripts
```bash
# Instead of hardcoded endpoints, use:
./get-cluster-login.sh
./cluster-manager.sh
```

### 3. Keep Info Files Updated
```bash
# Regularly update cluster info
./cluster-manager.sh  # Option 5
```

### 4. Verify Connection Before Operations
```bash
# Always check before troubleshooting
source ./cluster-utils.sh
check_cluster_login "rosa-cluster-dev"
```

## 🔗 Integration with Ansible

### Before Running Playbooks
```bash
# 1. Verify cluster connection
./cluster-manager.sh  # Option 4

# 2. Update cluster info if needed
./cluster-manager.sh  # Option 5

# 3. Run diagnostics if issues
./master-troubleshoot.sh  # Option 10
```

### Ansible Execution
```bash
cd /Users/swaroop/SIDKS/ansible
ansible-playbook playbooks/setup-harness.yml -e env=dev
```

### After Ansible Failures
```bash
# Troubleshoot specific issues
./master-troubleshoot.sh
# Select appropriate diagnostic option
```

## 📞 Support Commands

### Get Help
```bash
rosa --help
oc --help
./cluster-manager.sh
./master-troubleshoot.sh
```

### Emergency Recovery
```bash
# If completely lost connection
rosa list clusters
rosa describe cluster -c CLUSTER_NAME
rosa create admin -c CLUSTER_NAME
oc login API_URL --username cluster-admin
```

### Logs and Debugging
```bash
# Cluster installation logs
rosa logs install -c CLUSTER_NAME

# OpenShift events
oc get events --all-namespaces --sort-by='.lastTimestamp'

# Node status
oc get nodes -o wide
```

This comprehensive guide ensures you can always get current cluster information and maintain proper connections for troubleshooting and operations.
