#!/bin/bash
# =============================================================================
# Development Environment Configuration
# =============================================================================

# Override base configuration for dev environment
export ENV="dev"
export CLUSTER_NAME="rosa-cluster-dev"
export DELEGATE_NAME="rosa-harness-delegate-dev"

# Dev-specific namespaces
export TARGET_NAMESPACES=("cf-monitor" "cf-app" "cf-dev")

# Dev-specific resource limits (smaller for dev)
export CONTAINER_MEMORY_LIMIT="1024Mi"
export CONTAINER_MEMORY_REQUEST="1024Mi"
export CONTAINER_CPU_REQUEST="0.25"

# Dev-specific timeouts (shorter for faster feedback)
export POD_READY_TIMEOUT="30s"
export DEPLOYMENT_TIMEOUT="180s"

# Dev-specific debugging
export SCRIPT_DEBUG="true"
export VERBOSE_OUTPUT="true"

echo "✅ Loaded dev environment configuration"
