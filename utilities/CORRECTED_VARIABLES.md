# Corrected Variable Configuration - Single AWS Account

## ✅ **Corrected Configuration**

You're absolutely right! There is only **one AWS account: 818140567777**. Here are the corrected variables:

### 🌍 **AWS Account Variables (Corrected)**
| Variable | Corrected Value | Usage | Notes |
|----------|-----------------|-------|-------|
| `AWS_ACCOUNT` | `"818140567777"` | Single AWS account | ✅ Corrected |
| `ACCOUNT_ID` | Dynamic (`aws sts get-caller-identity`) | Current AWS account | ✅ Should match 818140567777 |
| ~~`SOURCE_ACCOUNT`~~ | ~~`"818140567777"`~~ | ❌ Removed | Not needed - same account |
| ~~`TARGET_ACCOUNT`~~ | ~~`"606639739464"`~~ | ❌ Removed | Incorrect - doesn't exist |

### 🐳 **ECR Configuration (Corrected)**
| Variable | Corrected Value | Usage | Notes |
|----------|-----------------|-------|-------|
| `ECR_REGISTRY` | `"818140567777.dkr.ecr.us-east-1.amazonaws.com"` | ECR registry URL | ✅ Correct |
| `ECR_REPO` | `"harness-delegate"` | ECR repository name | ✅ Correct |
| `REGION` | `"us-east-1"` | AWS region | ✅ Correct |

## 🔧 **Scripts Updated**

### **1. fix-iam-permissions.sh** ✅
- ❌ **Removed**: `TARGET_ACCOUNT="606639739464"`
- ❌ **Removed**: Cross-account ECR policy logic
- ✅ **Added**: `AWS_ACCOUNT="818140567777"`
- ✅ **Simplified**: Same-account ECR repository policy

### **2. setup-irsa-roles.sh** ✅
- ❌ **Removed**: Cross-account ECR resource references
- ✅ **Added**: `AWS_ACCOUNT="818140567777"`
- ✅ **Simplified**: Single-account ECR policy

### **3. cluster-info-dev.md** ✅
- ❌ **Removed**: References to target account 606639739464
- ✅ **Added**: Single account configuration note

## 📋 **Corrected ECR Policy**

### **Before (Incorrect - Cross-Account)**
```json
{
    "Resource": [
        "arn:aws:ecr:us-east-1:818140567777:repository/harness-delegate",
        "arn:aws:ecr:us-east-1:606639739464:repository/harness-delegate"
    ]
}
```

### **After (Correct - Single Account)**
```json
{
    "Resource": [
        "arn:aws:ecr:us-east-1:818140567777:repository/harness-delegate",
        "arn:aws:ecr:us-east-1:818140567777:repository/*"
    ]
}
```

## 🎯 **Simplified Architecture**

### **✅ Correct Setup:**
```
┌─────────────────────────────────────┐
│        AWS Account 818140567777      │
│                                     │
│  ┌─────────────────┐                │
│  │   ECR Registry  │                │
│  │  harness-delegate│               │
│  └─────────────────┘                │
│           ↑                         │
│           │                         │
│  ┌─────────────────┐                │
│  │  ROSA Cluster   │                │
│  │  (OpenShift)    │                │
│  │                 │                │
│  │  ┌─────────────┐│                │
│  │  │   Harness   ││                │
│  │  │  Delegate   ││                │
│  │  └─────────────┘│                │
│  └─────────────────┘                │
└─────────────────────────────────────┘
```

### **❌ Previous Incorrect Assumption:**
```
┌─────────────────┐    ┌─────────────────┐
│ Account         │    │ Account         │
│ 818140567777    │    │ 606639739464    │
│                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ECR Registry │ │    │ │ROSA Cluster │ │
│ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘
        ↑                       │
        └───── Cross Account ───┘
```

## 🚀 **Benefits of Correction**

### **✅ Simplified Configuration:**
- No cross-account IAM trust policies needed
- No cross-account ECR repository policies needed
- Simpler IAM role management
- Reduced complexity in troubleshooting

### **✅ Better Security:**
- No cross-account access required
- Simpler permission model
- Easier to audit and manage

### **✅ Easier Maintenance:**
- Single account to manage
- No cross-account policy synchronization
- Simpler troubleshooting

## 📊 **Updated Variable Summary**

### **Core Variables (Single Account)**
```bash
# Single AWS Account Configuration
AWS_ACCOUNT="818140567777"
REGION="us-east-1"
ECR_REGISTRY="818140567777.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPO="harness-delegate"

# Kubernetes Configuration
NAMESPACE="harness-delegate-ng"
SERVICE_ACCOUNT="cf-deploy"
DELEGATE_NAME="rosa-harness-delegate-dev"

# Target Namespaces
TARGET_NAMESPACES=("cf-monitor" "cf-app" "cf-dev")
```

## ✅ **Verification**

To verify the corrected configuration:

```bash
# Check current AWS account
aws sts get-caller-identity
# Should show: Account: 818140567777

# Check ECR repository
aws ecr describe-repositories --repository-names harness-delegate --region us-east-1
# Should show repository in account 818140567777

# Test ECR access
aws ecr get-login-password --region us-east-1
# Should work without cross-account issues
```

Thank you for the correction! The scripts now properly reflect the single AWS account (818140567777) setup, which will make the configuration much simpler and more reliable.
