#!/bin/bash

echo "🔄 Updating All Scripts to Use Configuration File"
echo "================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# List of scripts to update (excluding the ones already updated)
SCRIPTS_TO_UPDATE=(
    "fix-iam-permissions.sh"
    "fix-rosa-networking.sh"
    "fix-rosa-rbac.sh"
    "setup-irsa-roles.sh"
    "troubleshoot-ecr-connectivity.sh"
    "troubleshoot-iam-permissions.sh"
    "troubleshoot-network.sh"
    "master-troubleshoot.sh"
)

# Configuration loading template
CONFIG_TEMPLATE='# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Load environment-specific config if specified
if [[ -n "$1" ]]; then
    load_environment_config "$1"
fi'

echo "Scripts to update: ${#SCRIPTS_TO_UPDATE[@]}"
echo ""

for script in "${SCRIPTS_TO_UPDATE[@]}"; do
    if [[ -f "$script" ]]; then
        echo "📝 Updating $script..."
        
        # Create backup
        cp "$script" "${script}.backup"
        
        # Create temporary file with updated content
        {
            echo "#!/bin/bash"
            echo ""
            echo "# ============================================================================="
            echo "# $(basename "$script" .sh | tr '[:lower:]' '[:upper:]' | tr '-' ' ') SCRIPT"
            echo "# ============================================================================="
            echo ""
            echo "$CONFIG_TEMPLATE"
            echo ""
            echo "# Validate configuration"
            echo "if ! validate_config; then"
            echo "    echo \"❌ Configuration validation failed\""
            echo "    exit 1"
            echo "fi"
            echo ""
            echo "# Print current configuration if verbose"
            echo "print_config"
            echo ""
            
            # Add the rest of the script content, skipping the shebang and hardcoded variables
            tail -n +2 "$script" | sed \
                -e 's/ECR_REGISTRY="[^"]*"//g' \
                -e 's/ECR_REPO="[^"]*"//g' \
                -e 's/REGION="[^"]*"//g' \
                -e 's/NAMESPACE="[^"]*"//g' \
                -e 's/SERVICE_ACCOUNT="[^"]*"//g' \
                -e 's/DELEGATE_NAME="[^"]*"//g' \
                -e 's/CLUSTER_NAME="[^"]*"//g' \
                -e 's/AWS_ACCOUNT="[^"]*"//g' \
                -e 's/SECRET_NAME="[^"]*"//g' \
                -e 's/ECR_REGION="[^"]*"//g' \
                -e 's/TARGET_NAMESPACES=([^)]*)/# TARGET_NAMESPACES loaded from config/g' \
                -e 's/DEPLOY_NAMESPACES=([^)]*)/# DEPLOY_NAMESPACES loaded from config/g' \
                -e 's/$REGION/$AWS_REGION/g' \
                -e 's/$ECR_REGION/$AWS_REGION/g' \
                -e 's/$SECRET_NAME/$ECR_SECRET_NAME/g'
                
        } > "${script}.tmp"
        
        # Replace original with updated version
        mv "${script}.tmp" "$script"
        chmod +x "$script"
        
        echo "✅ Updated $script (backup saved as ${script}.backup)"
    else
        echo "⚠️  Script $script not found"
    fi
done

echo ""
echo "🎯 Script Update Complete!"
echo ""
echo "Summary of changes:"
echo "- Added configuration file loading to all scripts"
echo "- Replaced hardcoded variables with config references"
echo "- Added configuration validation"
echo "- Added environment-specific config support"
echo ""
echo "Usage examples:"
echo "# Use default (dev) configuration:"
echo "./fix-ecr-authentication.sh"
echo ""
echo "# Use specific environment:"
echo "./fix-ecr-authentication.sh prod"
echo ""
echo "# Test configuration:"
echo "source ./config.sh && validate_config"
