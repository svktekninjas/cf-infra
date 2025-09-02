#!/bin/bash

# Utility functions for ROSA cluster operations

# Get cluster API URL dynamically
get_cluster_api_url() {
    local cluster_name="${1:-rosa-cluster-dev}"
    rosa describe cluster -c "$cluster_name" 2>/dev/null | grep "API URL:" | awk '{print $3}'
}

# Get cluster console URL
get_cluster_console_url() {
    local cluster_name="${1:-rosa-cluster-dev}"
    rosa describe cluster -c "$cluster_name" 2>/dev/null | grep "Console URL:" | awk '{print $3}'
}

# Get cluster state
get_cluster_state() {
    local cluster_name="${1:-rosa-cluster-dev}"
    rosa describe cluster -c "$cluster_name" 2>/dev/null | grep "State:" | awk '{print $2}'
}

# Get OIDC issuer URL
get_oidc_issuer() {
    local cluster_name="${1:-rosa-cluster-dev}"
    rosa describe cluster -c "$cluster_name" 2>/dev/null | grep "OIDC Endpoint URL:" | awk '{print $4}' | sed 's/https:\/\///'
}

# Check if logged into correct cluster
check_cluster_login() {
    local expected_cluster_name="${1:-rosa-cluster-dev}"
    local expected_api_url=$(get_cluster_api_url "$expected_cluster_name")
    
    if ! oc whoami &>/dev/null; then
        echo "❌ Not logged into any OpenShift cluster"
        echo "Please login using: oc login $expected_api_url --username cluster-admin"
        return 1
    fi
    
    local current_server=$(oc whoami --show-server 2>/dev/null)
    if [ "$current_server" != "$expected_api_url" ]; then
        echo "⚠️  Logged into different cluster"
        echo "Current: $current_server"
        echo "Expected: $expected_api_url"
        echo "Please login to correct cluster: oc login $expected_api_url --username cluster-admin"
        return 1
    fi
    
    echo "✅ Logged into correct cluster: $expected_api_url"
    return 0
}

# Display cluster login instructions
show_login_instructions() {
    local cluster_name="${1:-rosa-cluster-dev}"
    local api_url=$(get_cluster_api_url "$cluster_name")
    local console_url=$(get_cluster_console_url "$cluster_name")
    
    echo ""
    echo "🔑 Login Instructions:"
    echo "====================="
    echo ""
    echo "Method 1 - CLI Login:"
    echo "oc login $api_url --username cluster-admin"
    echo ""
    echo "Method 2 - Web Console:"
    echo "1. Open: $console_url"
    echo "2. Login with your credentials"
    echo "3. Click username (top right) → Copy login command"
    echo "4. Run the provided oc login command"
    echo ""
    echo "Method 3 - Get admin password:"
    echo "rosa describe admin -c $cluster_name"
    echo ""
}

# Update cluster info file
update_cluster_info() {
    local cluster_name="${1:-rosa-cluster-dev}"
    local env="${2:-dev}"
    local info_file="/Users/swaroop/SIDKS/ansible/environments/$env/cluster-info-$env.md"
    
    echo "Updating cluster info file: $info_file"
    
    local cluster_info=$(rosa describe cluster -c "$cluster_name" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "❌ Could not get cluster information"
        return 1
    fi
    
    local api_url=$(echo "$cluster_info" | grep "API URL:" | awk '{print $3}')
    local console_url=$(echo "$cluster_info" | grep "Console URL:" | awk '{print $3}')
    local version=$(echo "$cluster_info" | grep "OpenShift Version:" | awk '{print $3}')
    local state=$(echo "$cluster_info" | grep "State:" | awk '{print $2}')
    local region=$(echo "$cluster_info" | grep "Region:" | awk '{print $2}')
    
    cat > "$info_file" << EOF
# ROSA Cluster Information - $env Environment
Generated on: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Cluster Details
- Name: $cluster_name
- State: $state
- Version: $version
- Region: $region
- Environment: $env

## Access URLs
- API URL: $api_url
- Console URL: $console_url

## Authentication
- Admin Username: cluster-admin
- Admin Password: (use 'rosa describe admin -c $cluster_name' to get password)

## Network Configuration
$(echo "$cluster_info" | grep -A 10 "Network:")

## OIDC Configuration
$(echo "$cluster_info" | grep "OIDC Endpoint URL:")

---
This file was updated automatically on $(date).
EOF
    
    echo "✅ Cluster info updated: $info_file"
}

# Export functions for use in other scripts
export -f get_cluster_api_url
export -f get_cluster_console_url  
export -f get_cluster_state
export -f get_oidc_issuer
export -f check_cluster_login
export -f show_login_instructions
export -f update_cluster_info
