#!/bin/bash
# =============================================================================
# Production Environment Configuration
# =============================================================================

# Override base configuration for prod environment
export ENV="prod"
export CLUSTER_NAME="rosa-cluster-prod"
export DELEGATE_NAME="rosa-harness-delegate-prod"

# Prod-specific namespaces
export TARGET_NAMESPACES=("cf-monitor-prod" "cf-app-prod" "cf-prod")

# Prod-specific resource limits (larger for prod)
export CONTAINER_MEMORY_LIMIT="4096Mi"
export CONTAINER_MEMORY_REQUEST="2048Mi"
export CONTAINER_CPU_REQUEST="1.0"

# Prod-specific timeouts (longer for stability)
export POD_READY_TIMEOUT="120s"
export DEPLOYMENT_TIMEOUT="600s"
export IAM_PROPAGATION_WAIT="120"

# Prod-specific debugging (disabled)
export SCRIPT_DEBUG="false"
export VERBOSE_OUTPUT="false"

echo "✅ Loaded prod environment configuration"
