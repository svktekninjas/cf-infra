# Complete ECR Connectivity Fix Guide

## 🎯 **Overview**
This guide provides step-by-step instructions to fix the Harness delegate ECR connectivity issues in your ROSA cluster.

## 📊 **Issues Identified**

### **1. Network Connectivity Issues**
- ❌ **Symptom**: `dial tcp [IP]:443: i/o timeout` for all external registries
- ❌ **Impact**: Cannot pull images from ECR, Docker Hub, Red Hat Registry
- ❌ **Root Cause**: Security groups/NAT gateway blocking outbound HTTPS

### **2. IAM Permission Issues**
- ❌ **Symptom**: Cannot describe ECR repositories or list images
- ❌ **Impact**: Limited ECR access despite having auth tokens
- ❌ **Root Cause**: Worker node IAM roles lack full ECR permissions

### **3. Service Account Issues**
- ❌ **Symptom**: cf-deploy references non-existent IAM role
- ❌ **Impact**: IRSA not working properly
- ❌ **Root Cause**: Missing/broken IRSA configuration

### **4. Cleanup Issues**
- ❌ **Symptom**: Multiple unused service accounts and old IAM policies
- ❌ **Impact**: Cluttered environment, potential conflicts
- ❌ **Root Cause**: Legacy resources from previous deployments

## 🚀 **Step-by-Step Fix Process**

### **Phase 1: Environment Preparation**

#### **Step 1: Verify Cluster Connection**
```bash
# Check current connection
oc whoami --show-server
oc whoami

# Should show:
# Server: https://api.o0r9m0f2v7l3b1c.55n4.p1.openshiftapps.com:6443
# User: cluster-admin
```

#### **Step 2: Navigate to Utilities**
```bash
cd /Users/swaroop/SIDKS/ansible/utilities
```

### **Phase 2: Cleanup (COMPLETED ✅)**

#### **Step 3: Remove Old IAM Policies** ✅ **DONE**
```bash
./remove-old-ecr-policies.sh
# Answer 'y' when prompted
```
**Result**: Removed 9 old CodePipeline ECR policies

#### **Step 4: Clean Service Accounts** ✅ **DONE**
```bash
./cleanup-service-accounts-iam.sh
# Answer 'y' when prompted
```
**Result**: Removed unused service accounts (builder, deployer, harness-delegate)

### **Phase 3: Diagnostics and Analysis**

#### **Step 5: Run Complete Diagnostics**
```bash
./master-troubleshoot.sh
# Select option 10 (Run All Diagnostics)
```

**Expected Results:**
- ✅ **Cluster Health**: All nodes ready
- ✅ **DNS Infrastructure**: Working properly
- ❌ **ECR Connectivity**: Timeout errors
- ❌ **IAM Permissions**: Limited ECR access
- ✅ **RBAC**: Service account permissions OK

### **Phase 4: Core Fixes**

#### **Step 6: Setup IRSA (IAM Roles for Service Accounts)**
```bash
./master-troubleshoot.sh
# Select option 8 (Setup IRSA)
```

**What this does:**
- Creates proper IAM role for cf-deploy service account
- Sets up OIDC trust policy
- Adds ECR permissions to the role
- Updates service account with correct role ARN

#### **Step 7: Fix IAM Permissions**
```bash
./master-troubleshoot.sh
# Select option 6 (Fix IAM Permissions)
```

**What this does:**
- Adds ECR policies to cluster worker roles
- Sets up cross-account ECR access (818140567777 ↔ 606639739464)
- Updates ECR repository policies

#### **Step 8: Fix Network Connectivity**
```bash
./master-troubleshoot.sh
# Select option 5 (Fix ROSA Networking)
```

**What this does:**
- Adds HTTPS outbound rules to security groups
- Creates ECR VPC endpoints for private connectivity
- Verifies NAT gateway routing
- Checks internet gateway configuration

#### **Step 9: Update ECR Authentication**
```bash
./master-troubleshoot.sh
# Select option 4 (Fix ECR Authentication)
```

**What this does:**
- Creates fresh ECR login secrets
- Updates service accounts with image pull secrets
- Tests ECR authentication

### **Phase 5: Installation**

#### **Step 10: Install Harness Delegate**
```bash
./master-troubleshoot.sh
# Select option 9 (Install Harness Delegate)
```

**What this does:**
- Deploys Harness delegate with proper configuration
- Uses fixed networking and authentication
- Monitors deployment status

### **Phase 6: Verification**

#### **Step 11: Verify Installation**
```bash
# Check delegate pods
oc get pods -n harness-delegate-ng

# Check pod logs
oc logs -f deployment/rosa-harness-delegate-dev -n harness-delegate-ng

# Check events
oc get events -n harness-delegate-ng --sort-by='.lastTimestamp'
```

## 🎯 **Alternative: Complete Fix (All-in-One)**

If you prefer to run all fixes at once:

```bash
./master-troubleshoot.sh
# Select option 11 (Complete Fix)
```

This runs all steps 6-10 automatically with proper timing and dependencies.

## 📋 **Execution Checklist**

### **Pre-Execution Checklist:**
- [ ] ✅ Connected to correct cluster
- [ ] ✅ Have cluster-admin permissions
- [ ] ✅ AWS CLI configured with proper permissions
- [ ] ✅ Cleanup completed (old policies and service accounts removed)

### **Execution Options:**

#### **Option A: Step-by-Step (Recommended for Learning)**
```bash
# Run each step individually
./master-troubleshoot.sh
# Select options 8, 6, 5, 4, 9 in sequence
```

#### **Option B: Complete Fix (Recommended for Speed)**
```bash
# Run all fixes at once
./master-troubleshoot.sh
# Select option 11 (Complete Fix)
```

### **Post-Execution Verification:**
- [ ] Delegate pods are running
- [ ] No ImagePullBackOff errors
- [ ] ECR connectivity working
- [ ] Harness delegate registered in Harness UI

## 🔧 **Expected Timeline**

| Phase | Duration | Description |
|-------|----------|-------------|
| Cleanup | ✅ **DONE** | Removed old policies and service accounts |
| Diagnostics | 5-10 minutes | Comprehensive system analysis |
| IRSA Setup | 2-3 minutes | Create IAM roles and trust policies |
| IAM Fix | 3-5 minutes | Update cluster role permissions |
| Network Fix | 5-10 minutes | Security groups and VPC endpoints |
| ECR Auth | 2-3 minutes | Update authentication secrets |
| Installation | 5-10 minutes | Deploy and verify delegate |
| **Total** | **20-35 minutes** | Complete end-to-end fix |

## 🚨 **Troubleshooting Common Issues**

### **If IRSA Setup Fails:**
```bash
# Check OIDC provider exists
aws iam list-open-id-connect-providers

# Verify cluster OIDC endpoint
oc get authentication cluster -o jsonpath='{.spec.serviceAccountIssuer}'
```

### **If Network Fix Fails:**
```bash
# Check VPC and security groups manually
aws ec2 describe-vpcs --filters "Name=tag:red-hat-clustertype,Values=rosa"
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=VPC_ID"
```

### **If ECR Auth Fails:**
```bash
# Test ECR access manually
aws ecr get-login-password --region us-east-1
aws ecr describe-repositories --repository-names harness-delegate
```

### **If Delegate Still Fails:**
```bash
# Check specific pod errors
oc describe pod POD_NAME -n harness-delegate-ng
oc logs POD_NAME -n harness-delegate-ng
```

## 📊 **Success Criteria**

### **Network Connectivity:**
- ✅ Pods can reach external registries (ECR, Docker Hub)
- ✅ No timeout errors in pod events
- ✅ VPC endpoints created and available

### **IAM Permissions:**
- ✅ Can describe ECR repositories
- ✅ Can list ECR images
- ✅ IRSA working properly

### **Service Accounts:**
- ✅ cf-deploy has proper IRSA role
- ✅ ECR image pull secrets configured
- ✅ No unused service accounts

### **Harness Delegate:**
- ✅ Pods in Running state
- ✅ Successfully pulled ECR image
- ✅ Delegate registered in Harness UI
- ✅ No error events

## 🎯 **Next Steps After Success**

1. **Verify Harness UI**: Check that delegate appears as connected
2. **Test Deployments**: Try deploying a simple application
3. **Monitor Performance**: Watch delegate logs for any issues
4. **Document Setup**: Save configuration for future reference

## 📞 **Support Commands**

```bash
# Quick status check
oc get pods -n harness-delegate-ng
oc get events -n harness-delegate-ng --sort-by='.lastTimestamp' | tail -10

# Detailed troubleshooting
./master-troubleshoot.sh  # Select option 10 for diagnostics

# Emergency reset
oc delete namespace harness-delegate-ng
# Then re-run complete fix
```

---

**Ready to proceed?** Start with the diagnostics (Step 5) and then choose your preferred execution path (Step-by-Step or Complete Fix).
