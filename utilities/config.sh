#!/bin/bash
# =============================================================================
# Centralized Configuration File for Harness Delegate Utilities
# =============================================================================
# This file contains all configurable variables used across utility scripts.
# Modify values here to customize for your environment.
# =============================================================================

# =============================================================================
# AWS CONFIGURATION
# =============================================================================
export AWS_ACCOUNT="818140567777"
export AWS_REGION="us-east-1"

# =============================================================================
# ECR CONFIGURATION
# =============================================================================
export ECR_REGISTRY="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"
export ECR_REPO="harness-delegate"
export ECR_SECRET_NAME="ecr-secret"

# =============================================================================
# CLUSTER CONFIGURATION
# =============================================================================
export CLUSTER_NAME="rosa-cluster-dev"
export DEFAULT_CLUSTER="rosa-cluster-dev"

# =============================================================================
# KUBERNETES/OPENSHIFT CONFIGURATION
# =============================================================================
export NAMESPACE="harness-delegate-ng"
export SERVICE_ACCOUNT="cf-deploy"
export DELEGATE_NAME="rosa-harness-delegate-dev"

# Target namespaces for deployments
export TARGET_NAMESPACES=("cf-monitor" "cf-app" "cf-dev")
export DEPLOY_NAMESPACES=("cf-monitor" "cf-app" "cf-dev")

# =============================================================================
# IAM CONFIGURATION
# =============================================================================
export IAM_POLICY_PREFIX="ROSAECRAccess"
export IRSA_ROLE_PREFIX="current-cluster"
export IRSA_POLICY_PREFIX="current-cluster"

# Derived IAM names (based on cluster)
export ECR_POLICY_NAME="${IAM_POLICY_PREFIX}-${CLUSTER_NAME}"
export IRSA_ROLE_NAME="${IRSA_ROLE_PREFIX}-harness-delegate-irsa"
export IRSA_POLICY_NAME="${IRSA_POLICY_PREFIX}-harness-delegate-ecr-policy"

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================
export VPC_ENDPOINT_PREFIX="ECR"

# =============================================================================
# HARNESS CONFIGURATION
# =============================================================================
export HARNESS_ACCOUNT_ID="YOUR_HARNESS_ACCOUNT_ID"
export HARNESS_MANAGER_HOST="https://app.harness.io"
export HARNESS_LOG_SERVICE_URL="https://app.harness.io/log-service/"

# =============================================================================
# CONTAINER CONFIGURATION
# =============================================================================
export CONTAINER_MEMORY_LIMIT="2048Mi"
export CONTAINER_MEMORY_REQUEST="2048Mi"
export CONTAINER_CPU_REQUEST="0.5"
export JAVA_OPTS="-Xms64M"

# =============================================================================
# TIMEOUT CONFIGURATION
# =============================================================================
export POD_READY_TIMEOUT="60s"
export DEPLOYMENT_TIMEOUT="300s"
export IAM_PROPAGATION_WAIT="60"
export NETWORK_PROPAGATION_WAIT="180"

# =============================================================================
# PATH CONFIGURATION
# =============================================================================
export UTILITIES_DIR="/Users/swaroop/SIDKS/ansible/utilities"
export ENVIRONMENTS_DIR="/Users/swaroop/SIDKS/ansible/environments"
export CONFIG_DIR="${UTILITIES_DIR}/config"

# =============================================================================
# SCRIPT CONFIGURATION
# =============================================================================
export SCRIPT_DEBUG="false"
export VERBOSE_OUTPUT="false"

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================
validate_config() {
    local required_vars=(
        "AWS_ACCOUNT"
        "AWS_REGION" 
        "ECR_REGISTRY"
        "ECR_REPO"
        "NAMESPACE"
        "SERVICE_ACCOUNT"
        "DELEGATE_NAME"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo "❌ Missing required configuration variables:"
        printf '   - %s\n' "${missing_vars[@]}"
        return 1
    fi
    
    return 0
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================
get_ecr_registry_url() {
    echo "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"
}

get_ecr_repo_url() {
    echo "${ECR_REGISTRY}/${ECR_REPO}"
}

get_iam_role_arn() {
    local role_name="$1"
    echo "arn:aws:iam::${AWS_ACCOUNT}:role/${role_name}"
}

get_ecr_repo_arn() {
    echo "arn:aws:ecr:${AWS_REGION}:${AWS_ACCOUNT}:repository/${ECR_REPO}"
}

get_deploy_role_name() {
    local namespace="$1"
    echo "${IRSA_ROLE_PREFIX}-${namespace}-deployer-irsa"
}

# =============================================================================
# ENVIRONMENT-SPECIFIC OVERRIDES
# =============================================================================
load_environment_config() {
    local env="${1:-dev}"
    local env_config="${CONFIG_DIR}/${env}-config.sh"
    
    if [[ -f "$env_config" ]]; then
        echo "Loading environment config: $env_config"
        source "$env_config"
    fi
}

# =============================================================================
# DEBUG FUNCTIONS
# =============================================================================
print_config() {
    if [[ "$VERBOSE_OUTPUT" == "true" ]]; then
        echo "=== CONFIGURATION ==="
        echo "AWS Account: $AWS_ACCOUNT"
        echo "AWS Region: $AWS_REGION"
        echo "ECR Registry: $ECR_REGISTRY"
        echo "ECR Repository: $ECR_REPO"
        echo "Namespace: $NAMESPACE"
        echo "Service Account: $SERVICE_ACCOUNT"
        echo "Delegate Name: $DELEGATE_NAME"
        echo "Target Namespaces: ${TARGET_NAMESPACES[*]}"
        echo "===================="
    fi
}

# =============================================================================
# INITIALIZATION
# =============================================================================
# Validate configuration when sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Being sourced
    if ! validate_config; then
        echo "❌ Configuration validation failed"
        return 1
    fi
    
    print_config
fi

# =============================================================================
# EXPORT ALL FUNCTIONS
# =============================================================================
export -f validate_config
export -f get_ecr_registry_url
export -f get_ecr_repo_url
export -f get_iam_role_arn
export -f get_ecr_repo_arn
export -f get_deploy_role_name
export -f load_environment_config
export -f print_config
