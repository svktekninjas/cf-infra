# Utility Scripts Variable Analysis

## 📊 **Variable Categories Identified**

### 🌐 **Cluster & Infrastructure Variables**
| Variable | Current Value | Usage | Scripts |
|----------|---------------|-------|---------|
| `CLUSTER_NAME` | `rosa-cluster-dev` | ROSA cluster identifier | Multiple scripts |
| `CURRENT_API_URL` | Dynamic (`oc whoami --show-server`) | Current cluster API endpoint | Most scripts |
| `CURRENT_USER` | Dynamic (`oc whoami`) | Current cluster user | Most scripts |
| `API_URL` | Dynamic | Cluster API endpoint | cluster-utils, cluster-manager |
| `CONSOLE_URL` | Dynamic | Web console URL | cluster-utils, cluster-manager |
| `CLUSTER_STATE` | Dynamic | Cluster state (ready/installing) | cluster-utils |
| `OIDC_ISSUER` | Dynamic | OIDC provider for IRSA | setup-irsa-roles |

### 🌍 **AWS Region & Account Variables**
| Variable | Current Value | Usage | Scripts |
|----------|---------------|-------|---------|
| `REGION` | `us-east-1` | AWS region | Most AWS-related scripts |
| `ACCOUNT_ID` | Dynamic (`aws sts get-caller-identity`) | Current AWS account | IAM scripts |
| `SOURCE_ACCOUNT` | `818140567777` | ECR source account | fix-iam-permissions |
| `TARGET_ACCOUNT` | `606639739464` | ECR target account | fix-iam-permissions |

### 🐳 **ECR & Container Variables**
| Variable | Current Value | Usage | Scripts |
|----------|---------------|-------|---------|
| `ECR_REGISTRY` | `818140567777.dkr.ecr.us-east-1.amazonaws.com` | ECR registry URL | Multiple scripts |
| `ECR_REPO` | `harness-delegate` | ECR repository name | Multiple scripts |
| `ECR_TOKEN` | Dynamic (`aws ecr get-login-password`) | ECR authentication token | Authentication scripts |

### 🏗️ **Kubernetes & OpenShift Variables**
| Variable | Current Value | Usage | Scripts |
|----------|---------------|-------|---------|
| `NAMESPACE` | `harness-delegate-ng` | Primary namespace | Most scripts |
| `SERVICE_ACCOUNT` | `cf-deploy` | Main service account | Multiple scripts |
| `DELEGATE_NAME` | `rosa-harness-delegate-dev` | Harness delegate name | Installation scripts |
| `TARGET_NAMESPACES` | `["cf-monitor", "cf-app", "cf-dev"]` | Deployment namespaces | RBAC scripts |

### 🔐 **IAM & Security Variables**
| Variable | Current Value | Usage | Scripts |
|----------|---------------|-------|---------|
| `ROLE_NAME` | Dynamic (various patterns) | IAM role names | IAM scripts |
| `POLICY_NAME` | Dynamic (various patterns) | IAM policy names | IAM scripts |
| `POLICY_ARN` | Dynamic | IAM policy ARNs | IAM scripts |
| `WORKER_ROLE` | Dynamic | ROSA worker node role | fix-iam-permissions |
| `IMAGE_REGISTRY_ROLE` | Dynamic | ROSA image registry role | fix-iam-permissions |

### 🌐 **Network Variables**
| Variable | Current Value | Usage | Scripts |
|----------|---------------|-------|---------|
| `VPC_ID` | Dynamic (discovered from worker nodes) | VPC identifier | Network scripts |
| `PRIVATE_SUBNETS` | Dynamic | Private subnet IDs | Network scripts |
| `SECURITY_GROUPS` | Dynamic | Security group IDs | Network scripts |
| `NAT_GATEWAYS` | Dynamic | NAT gateway information | Network scripts |
| `WORKER_NODES` | Dynamic | Worker node instance IDs | Network scripts |

## 📋 **Script-by-Script Variable Breakdown**

### **1. master-troubleshoot.sh**
```bash
# Dynamic Variables
CURRENT_API_URL=$(oc whoami --show-server)
CURRENT_USER=$(oc whoami)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

### **2. cluster-manager.sh**
```bash
# Static Variables
DEFAULT_CLUSTER="rosa-cluster-dev"

# Dynamic Variables (via functions)
API_URL=$(get_cluster_api_url)
CONSOLE_URL=$(get_cluster_console_url)
CLUSTER_STATE=$(get_cluster_state)
```

### **3. cluster-utils.sh**
```bash
# Function Parameters
cluster_name="${1:-rosa-cluster-dev}"  # Default cluster name
expected_cluster_name="${1:-rosa-cluster-dev}"
env="${2:-dev}"  # Environment
```

### **4. troubleshoot-ecr-connectivity.sh**
```bash
# Static Variables
ECR_REGISTRY="818140567777.dkr.ecr.us-east-1.amazonaws.com"
NAMESPACE="harness-delegate-ng"

# Dynamic Variables
CURRENT_API_URL=$(oc whoami --show-server)
CURRENT_USER=$(oc whoami)
```

### **5. troubleshoot-network.sh**
```bash
# Static Variables
REGION="us-east-1"

# Dynamic Variables
CURRENT_API_URL=$(oc whoami --show-server)
CURRENT_USER=$(oc whoami)
```

### **6. troubleshoot-iam-permissions.sh**
```bash
# Static Variables
ECR_REGISTRY="818140567777.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPO="harness-delegate"
REGION="us-east-1"
NAMESPACE="harness-delegate-ng"

# Dynamic Variables
CURRENT_API_URL=$(oc whoami --show-server)
CURRENT_USER=$(oc whoami)
CURRENT_AWS_USER=$(aws sts get-caller-identity --query 'Arn' --output text)
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
WORKER_INSTANCES=$(oc get nodes -o jsonpath='{.items[*].spec.providerID}')
```

### **7. fix-ecr-authentication.sh**
```bash
# Static Variables
ECR_REGISTRY="818140567777.dkr.ecr.us-east-1.amazonaws.com"
NAMESPACE="harness-delegate-ng"
SERVICE_ACCOUNT="cf-deploy"
REGION="us-east-1"

# Dynamic Variables
CURRENT_API_URL=$(oc whoami --show-server)
CURRENT_USER=$(oc whoami)
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
ECR_TOKEN=$(aws ecr get-login-password --region $REGION)
```

### **8. fix-rosa-networking.sh**
```bash
# Static Variables
REGION="us-east-1"

# Dynamic Variables
CURRENT_API_URL=$(oc whoami --show-server)
CURRENT_USER=$(oc whoami)
WORKER_NODES=$(oc get nodes -o jsonpath='{.items[*].spec.providerID}')
VPC_ID=$(aws ec2 describe-instances --instance-ids "$WORKER_NODES" --query 'Reservations[0].Instances[0].VpcId')
SECURITY_GROUPS=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPC_ID")
PRIVATE_SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID")
```

### **9. fix-iam-permissions.sh**
```bash
# Static Variables
CLUSTER_NAME="rosa-cluster-dev"
ECR_REPO="harness-delegate"
REGION="us-east-1"
SOURCE_ACCOUNT="818140567777"
TARGET_ACCOUNT="606639739464"

# Dynamic Variables
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
CURRENT_USER=$(aws sts get-caller-identity --query 'Arn' --output text)
OPERATOR_ROLES=$(rosa describe cluster -c $CLUSTER_NAME | grep "arn:aws:iam")
IMAGE_REGISTRY_ROLE=$(echo "$OPERATOR_ROLES" | grep "image-registry")
WORKER_ROLE=$(rosa describe cluster -c $CLUSTER_NAME | grep "Worker:")
```

### **10. fix-rosa-rbac.sh**
```bash
# Static Variables
NAMESPACE="harness-delegate-ng"
SERVICE_ACCOUNT="cf-deploy"
DELEGATE_NAME="rosa-harness-delegate-dev"
TARGET_NAMESPACES=("cf-monitor" "cf-app" "cf-dev")

# Dynamic Variables
CURRENT_USER=$(oc whoami)
```

### **11. setup-irsa-roles.sh**
```bash
# Static Variables
REGION="us-east-1"
NAMESPACE="harness-delegate-ng"
SERVICE_ACCOUNT="cf-deploy"
ECR_REPO="harness-delegate"
DEPLOY_NAMESPACES=("cf-monitor" "cf-app" "cf-dev")

# Dynamic Variables
CURRENT_API_URL=$(oc whoami --show-server)
CURRENT_USER=$(oc whoami)
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
OIDC_ISSUER=$(oc get authentication cluster -o jsonpath='{.spec.serviceAccountIssuer}')
ROLE_NAME="current-cluster-harness-delegate-irsa"
POLICY_NAME="current-cluster-harness-delegate-ecr-policy"
```

### **12. install-harness-delegate.sh**
```bash
# Static Variables
NAMESPACE="harness-delegate-ng"
DELEGATE_NAME="rosa-harness-delegate-dev"
ECR_REGISTRY="818140567777.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPO="harness-delegate"
REGION="us-east-1"

# Dynamic Variables
CURRENT_API=$(oc whoami --show-server)
CURRENT_USER=$(oc whoami)
ECR_TOKEN=$(aws ecr get-login-password --region $REGION)
DELEGATE_POD=$(oc get pods -n $NAMESPACE -l harness.io/name=$DELEGATE_NAME)
```

## 🔧 **Variable Patterns & Consistency**

### **✅ Consistent Variables Across Scripts:**
- `REGION="us-east-1"` - Used in all AWS-related scripts
- `NAMESPACE="harness-delegate-ng"` - Primary namespace
- `ECR_REGISTRY="818140567777.dkr.ecr.us-east-1.amazonaws.com"` - ECR registry
- `ECR_REPO="harness-delegate"` - ECR repository name
- `SERVICE_ACCOUNT="cf-deploy"` - Main service account

### **✅ Dynamic Detection Patterns:**
- `CURRENT_API_URL=$(oc whoami --show-server)` - Current cluster API
- `CURRENT_USER=$(oc whoami)` - Current cluster user
- `ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)` - AWS account
- `VPC_ID` - Discovered from worker nodes
- `OIDC_ISSUER` - Retrieved from cluster authentication

### **⚠️ Variables That May Need Customization:**
- `CLUSTER_NAME="rosa-cluster-dev"` - May not match actual cluster
- `SOURCE_ACCOUNT="818140567777"` - ECR source account
- `TARGET_ACCOUNT="606639739464"` - ECR target account
- `TARGET_NAMESPACES=("cf-monitor" "cf-app" "cf-dev")` - Deployment namespaces

## 🎯 **Recommendations for Variable Management**

### **1. Create Central Configuration File**
```bash
# config/cluster-config.sh
export REGION="us-east-1"
export ECR_REGISTRY="818140567777.dkr.ecr.us-east-1.amazonaws.com"
export ECR_REPO="harness-delegate"
export NAMESPACE="harness-delegate-ng"
export SERVICE_ACCOUNT="cf-deploy"
export DELEGATE_NAME="rosa-harness-delegate-dev"
export TARGET_NAMESPACES=("cf-monitor" "cf-app" "cf-dev")
```

### **2. Environment-Specific Overrides**
```bash
# config/dev-config.sh
export ENV="dev"
export CLUSTER_NAME="rosa-cluster-dev"

# config/prod-config.sh
export ENV="prod"
export CLUSTER_NAME="rosa-cluster-prod"
```

### **3. Dynamic Variable Functions**
```bash
# Common functions for dynamic variables
get_current_cluster() { oc whoami --show-server; }
get_current_user() { oc whoami; }
get_aws_account() { aws sts get-caller-identity --query 'Account' --output text; }
get_vpc_from_cluster() { # VPC discovery logic }
```

This analysis shows that most scripts are well-structured with consistent variable usage, but could benefit from centralized configuration management.
