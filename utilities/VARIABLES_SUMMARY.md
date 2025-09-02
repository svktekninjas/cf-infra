# Comprehensive Variable Analysis - Utility Scripts

## 🎯 **Executive Summary**

Analysis of 16 utility scripts reveals **78 unique variables** across 6 main categories. Most variables are consistently defined, with good use of dynamic detection patterns.

## 📊 **Variable Categories & Values**

### 🌐 **1. Cluster & Infrastructure (12 variables)**
| Variable | Value | Type | Usage Count |
|----------|-------|------|-------------|
| `CLUSTER_NAME` | `"rosa-cluster-dev"` | Static | 4 scripts |
| `CURRENT_API_URL` | `$(oc whoami --show-server)` | Dynamic | 8 scripts |
| `CURRENT_USER` | `$(oc whoami)` | Dynamic | 8 scripts |
| `CURRENT_API` | `$(oc whoami --show-server)` | Dynamic | 2 scripts |
| `API_URL` | Dynamic from ROSA | Dynamic | 2 scripts |
| `CONSOLE_URL` | Dynamic from ROSA | Dynamic | 2 scripts |
| `CLUSTER_STATE` | Dynamic from ROSA | Dynamic | 2 scripts |
| `CLUSTER_INFO` | `$(rosa describe cluster)` | Dynamic | 1 script |
| `DEFAULT_CLUSTER` | `"rosa-cluster-dev"` | Static | 1 script |
| `SCRIPT_DIR` | `$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)` | Dynamic | 2 scripts |
| `ADMIN_INFO` | `$(rosa describe admin)` | Dynamic | 1 script |
| `OIDC_ISSUER` | Dynamic from cluster | Dynamic | 1 script |

### 🌍 **2. AWS Region & Account (8 variables)**
| Variable | Value | Type | Usage Count |
|----------|-------|------|-------------|
| `REGION` | `"us-east-1"` | Static | 7 scripts |
| `ECR_REGION` | `"us-east-1"` | Static | 1 script |
| `ACCOUNT_ID` | `$(aws sts get-caller-identity)` | Dynamic | 4 scripts |
| `AWS_ACCOUNT` | `$(aws sts get-caller-identity)` | Dynamic | 1 script |
| `CURRENT_USER` | `$(aws sts get-caller-identity)` | Dynamic | 1 script |
| `CURRENT_AWS_USER` | `$(aws sts get-caller-identity)` | Dynamic | 1 script |
| `SOURCE_ACCOUNT` | `"818140567777"` | Static | 1 script |
| `TARGET_ACCOUNT` | `"606639739464"` | Static | 1 script |

### 🐳 **3. ECR & Container (6 variables)**
| Variable | Value | Type | Usage Count |
|----------|-------|------|-------------|
| `ECR_REGISTRY` | `"818140567777.dkr.ecr.us-east-1.amazonaws.com"` | Static | 6 scripts |
| `ECR_REPO` | `"harness-delegate"` | Static | 5 scripts |
| `ECR_TOKEN` | `$(aws ecr get-login-password)` | Dynamic | 2 scripts |
| `SECRET_NAME` | `"ecr-secret"` | Static | 1 script |
| `DELEGATE_NAME` | `"rosa-harness-delegate-dev"` | Static | 3 scripts |
| `DELEGATE_POD` | Dynamic from oc | Dynamic | 1 script |

### 🏗️ **4. Kubernetes & OpenShift (8 variables)**
| Variable | Value | Type | Usage Count |
|----------|-------|------|-------------|
| `NAMESPACE` | `"harness-delegate-ng"` | Static | 9 scripts |
| `SERVICE_ACCOUNT` | `"cf-deploy"` | Static | 4 scripts |
| `TARGET_NAMESPACES` | `("cf-monitor" "cf-app" "cf-dev")` | Static | 2 scripts |
| `DEPLOY_NAMESPACES` | `("cf-monitor" "cf-app" "cf-dev")` | Static | 1 script |
| `POD_STATUS` | Dynamic from oc | Dynamic | 1 script |
| `ROLE_ARN` | Dynamic | Dynamic | 1 script |
| `TRUST_POLICY` | Dynamic JSON | Dynamic | 1 script |
| `ECR_POLICY` | Dynamic JSON | Dynamic | 1 script |

### 🔐 **5. IAM & Security (15 variables)**
| Variable | Value | Type | Usage Count |
|----------|-------|------|-------------|
| `ROLE_NAME` | Various patterns | Dynamic | 3 scripts |
| `POLICY_NAME` | Various patterns | Dynamic | 3 scripts |
| `POLICY_ARN` | Dynamic | Dynamic | 2 scripts |
| `EXISTING_POLICY` | Dynamic | Dynamic | 1 script |
| `WORKER_ROLE` | Dynamic from ROSA | Dynamic | 1 script |
| `IMAGE_REGISTRY_ROLE` | Dynamic from ROSA | Dynamic | 1 script |
| `OPERATOR_ROLES` | Dynamic from ROSA | Dynamic | 1 script |
| `WORKER_INSTANCES` | Dynamic from oc | Dynamic | 1 script |
| `ECR_POLICY_DOC` | Dynamic JSON | Dynamic | 1 script |
| `OIDC_PROVIDER_EXISTS` | Dynamic | Dynamic | 1 script |
| `OLD_POLICIES` | Array of policy names | Static | 1 script |
| `DEPLOY_ROLE_NAME` | Dynamic | Dynamic | 1 script |
| `DEPLOY_TRUST_POLICY` | Dynamic JSON | Dynamic | 1 script |
| `DEPLOY_ROLE_ARN` | Dynamic | Dynamic | 1 script |
| `ATTACHED_ROLES` | Dynamic | Dynamic | 1 script |

### 🌐 **6. Network Variables (29 variables)**
| Variable | Value | Type | Usage Count |
|----------|-------|------|-------------|
| `VPC_ID` | Dynamic discovery | Dynamic | 2 scripts |
| `WORKER_NODES` | Dynamic from oc | Dynamic | 2 scripts |
| `SECURITY_GROUPS` | Dynamic from AWS | Dynamic | 1 script |
| `PRIVATE_SUBNETS` | Dynamic from AWS | Dynamic | 1 script |
| `NAT_GATEWAYS` | Dynamic from AWS | Dynamic | 1 script |
| `IGW` | Dynamic from AWS | Dynamic | 1 script |
| `ECR_ENDPOINT` | Dynamic from AWS | Dynamic | 1 script |
| `ROUTE_TABLE` | Dynamic from AWS | Dynamic | 1 script |
| `NAT_ROUTE` | Dynamic from AWS | Dynamic | 1 script |
| `HTTPS_RULE` | Dynamic from AWS | Dynamic | 1 script |
| `SUBNET_IDS` | Dynamic | Dynamic | 1 script |
| `DEFAULT_SG` | Dynamic | Dynamic | 1 script |
| ... (17 more network-related variables) | | | |

## 🔧 **Variable Patterns Analysis**

### **✅ Consistent Static Variables (Used Across Multiple Scripts)**
```bash
REGION="us-east-1"                    # 7 scripts
NAMESPACE="harness-delegate-ng"       # 9 scripts  
ECR_REGISTRY="818140567777.dkr.ecr.us-east-1.amazonaws.com"  # 6 scripts
ECR_REPO="harness-delegate"           # 5 scripts
SERVICE_ACCOUNT="cf-deploy"           # 4 scripts
```

### **✅ Consistent Dynamic Patterns**
```bash
CURRENT_API_URL=$(oc whoami --show-server)     # 8 scripts
CURRENT_USER=$(oc whoami)                      # 8 scripts
ACCOUNT_ID=$(aws sts get-caller-identity)      # 4 scripts
ECR_TOKEN=$(aws ecr get-login-password)        # 2 scripts
```

### **⚠️ Inconsistent Naming Patterns**
```bash
# Same concept, different names:
CURRENT_API_URL vs CURRENT_API
CURRENT_USER vs CURRENT_AWS_USER  
ECR_REGION vs REGION
```

## 🎯 **Recommendations**

### **1. Create Central Configuration**
```bash
# config/common-vars.sh
export REGION="us-east-1"
export NAMESPACE="harness-delegate-ng"
export SERVICE_ACCOUNT="cf-deploy"
export ECR_REGISTRY="818140567777.dkr.ecr.us-east-1.amazonaws.com"
export ECR_REPO="harness-delegate"
export DELEGATE_NAME="rosa-harness-delegate-dev"
export TARGET_NAMESPACES=("cf-monitor" "cf-app" "cf-dev")
```

### **2. Standardize Dynamic Detection Functions**
```bash
# config/dynamic-vars.sh
get_current_cluster_api() { oc whoami --show-server 2>/dev/null; }
get_current_user() { oc whoami 2>/dev/null; }
get_aws_account() { aws sts get-caller-identity --query 'Account' --output text; }
get_ecr_token() { aws ecr get-login-password --region ${REGION:-us-east-1}; }
```

### **3. Environment-Specific Overrides**
```bash
# config/dev-vars.sh
export ENV="dev"
export CLUSTER_NAME="rosa-cluster-dev"

# config/prod-vars.sh  
export ENV="prod"
export CLUSTER_NAME="rosa-cluster-prod"
```

### **4. Variable Validation**
```bash
# config/validate-vars.sh
validate_required_vars() {
    local required_vars=("REGION" "NAMESPACE" "ECR_REGISTRY")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            echo "❌ Required variable $var is not set"
            exit 1
        fi
    done
}
```

## 📋 **High-Priority Variables to Centralize**

### **Critical (Used in 5+ scripts)**
- `NAMESPACE="harness-delegate-ng"`
- `REGION="us-east-1"`  
- `ECR_REGISTRY="818140567777.dkr.ecr.us-east-1.amazonaws.com"`
- `ECR_REPO="harness-delegate"`

### **Important (Used in 3-4 scripts)**
- `SERVICE_ACCOUNT="cf-deploy"`
- `CLUSTER_NAME="rosa-cluster-dev"`
- `ACCOUNT_ID` (dynamic)

### **Dynamic Patterns to Standardize**
- Cluster API detection: `$(oc whoami --show-server)`
- Current user detection: `$(oc whoami)`
- AWS account detection: `$(aws sts get-caller-identity)`

This analysis shows the scripts are well-structured but would benefit from centralized variable management to improve maintainability and consistency.
