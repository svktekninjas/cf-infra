#!/bin/bash

# Source cluster utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/cluster-utils.sh"

echo "🏗️  ROSA Cluster Management Script"
echo "================================="

# Default cluster name
DEFAULT_CLUSTER="rosa-cluster-dev"

echo "Available operations:"
echo "1. List all clusters"
echo "2. Get cluster details"
echo "3. Get login instructions"
echo "4. Check current connection"
echo "5. Update cluster info files"
echo "6. Get admin credentials"
echo "7. Download kubeconfig"
echo "8. Test cluster connectivity"
echo "9. Show cluster endpoints"
echo "10. Complete cluster setup guide"
echo ""

read -p "Select operation (1-10): " choice

case $choice in
    1)
        echo ""
        echo "📋 Available ROSA Clusters:"
        echo "=========================="
        rosa list clusters
        ;;
    
    2)
        read -p "Enter cluster name [$DEFAULT_CLUSTER]: " cluster_name
        cluster_name=${cluster_name:-$DEFAULT_CLUSTER}
        
        echo ""
        echo "📊 Cluster Details: $cluster_name"
        echo "================================"
        rosa describe cluster -c "$cluster_name"
        ;;
    
    3)
        read -p "Enter cluster name [$DEFAULT_CLUSTER]: " cluster_name
        cluster_name=${cluster_name:-$DEFAULT_CLUSTER}
        
        echo ""
        echo "🔑 Login Instructions for: $cluster_name"
        show_login_instructions "$cluster_name"
        ;;
    
    4)
        read -p "Enter expected cluster name [$DEFAULT_CLUSTER]: " cluster_name
        cluster_name=${cluster_name:-$DEFAULT_CLUSTER}
        
        echo ""
        echo "🔍 Current Connection Status:"
        echo "============================"
        check_cluster_login "$cluster_name"
        ;;
    
    5)
        read -p "Enter cluster name [$DEFAULT_CLUSTER]: " cluster_name
        cluster_name=${cluster_name:-$DEFAULT_CLUSTER}
        read -p "Enter environment [dev]: " env
        env=${env:-dev}
        
        echo ""
        echo "📝 Updating cluster info files..."
        update_cluster_info "$cluster_name" "$env"
        
        # Also update the connect script
        echo "Updating connect script..."
        cp "$SCRIPT_DIR/../environments/$env/connect-$env.sh" "$SCRIPT_DIR/../environments/$env/connect-$env.sh.bak"
        echo "✅ Backup created: connect-$env.sh.bak"
        echo "✅ Files updated successfully"
        ;;
    
    6)
        read -p "Enter cluster name [$DEFAULT_CLUSTER]: " cluster_name
        cluster_name=${cluster_name:-$DEFAULT_CLUSTER}
        
        echo ""
        echo "🔐 Admin Credentials for: $cluster_name"
        echo "====================================="
        
        # Check if admin exists
        if rosa describe admin -c "$cluster_name" &>/dev/null; then
            echo "✅ Admin user exists"
            rosa describe admin -c "$cluster_name"
        else
            echo "⚠️  No admin user found. Creating one..."
            rosa create admin -c "$cluster_name"
        fi
        ;;
    
    7)
        read -p "Enter cluster name [$DEFAULT_CLUSTER]: " cluster_name
        cluster_name=${cluster_name:-$DEFAULT_CLUSTER}
        
        echo ""
        echo "📥 Downloading kubeconfig for: $cluster_name"
        echo "==========================================="
        rosa download kubeconfig -c "$cluster_name"
        
        if [ $? -eq 0 ]; then
            echo "✅ Kubeconfig downloaded successfully"
            echo "You can now use kubectl/oc commands"
        else
            echo "❌ Failed to download kubeconfig"
        fi
        ;;
    
    8)
        read -p "Enter cluster name [$DEFAULT_CLUSTER]: " cluster_name
        cluster_name=${cluster_name:-$DEFAULT_CLUSTER}
        
        echo ""
        echo "🧪 Testing Connectivity to: $cluster_name"
        echo "========================================"
        
        # Get cluster state
        state=$(get_cluster_state "$cluster_name")
        api_url=$(get_cluster_api_url "$cluster_name")
        
        echo "Cluster state: $state"
        echo "API URL: $api_url"
        
        if [ "$state" = "ready" ]; then
            echo "✅ Cluster is ready"
            
            # Test API connectivity
            echo "Testing API connectivity..."
            if curl -k -s --max-time 10 "$api_url/healthz" &>/dev/null; then
                echo "✅ API endpoint is reachable"
            else
                echo "⚠️  API endpoint connectivity issues"
            fi
            
            # Test authentication if logged in
            if oc whoami &>/dev/null; then
                echo "✅ Authentication working"
                echo "Current user: $(oc whoami)"
            else
                echo "⚠️  Not authenticated"
            fi
        else
            echo "⚠️  Cluster not ready. State: $state"
        fi
        ;;
    
    9)
        read -p "Enter cluster name [$DEFAULT_CLUSTER]: " cluster_name
        cluster_name=${cluster_name:-$DEFAULT_CLUSTER}
        
        echo ""
        echo "🌐 Cluster Endpoints for: $cluster_name"
        echo "====================================="
        
        api_url=$(get_cluster_api_url "$cluster_name")
        console_url=$(get_cluster_console_url "$cluster_name")
        oidc_issuer=$(get_oidc_issuer "$cluster_name")
        
        echo "API URL:      $api_url"
        echo "Console URL:  $console_url"
        echo "OIDC Issuer:  https://$oidc_issuer"
        
        echo ""
        echo "📋 Quick Commands:"
        echo "=================="
        echo "Login:        oc login $api_url --username cluster-admin"
        echo "Web Console:  open $console_url"
        echo "Get Admin:    rosa describe admin -c $cluster_name"
        ;;
    
    10)
        read -p "Enter cluster name [$DEFAULT_CLUSTER]: " cluster_name
        cluster_name=${cluster_name:-$DEFAULT_CLUSTER}
        
        echo ""
        echo "📚 Complete Cluster Setup Guide for: $cluster_name"
        echo "================================================="
        
        # Step 1: Check cluster exists
        echo "Step 1: Verify cluster exists"
        echo "-----------------------------"
        if rosa describe cluster -c "$cluster_name" &>/dev/null; then
            echo "✅ Cluster '$cluster_name' found"
            state=$(get_cluster_state "$cluster_name")
            echo "   State: $state"
            
            if [ "$state" != "ready" ]; then
                echo "⚠️  Cluster not ready. Please wait for it to be ready."
                exit 1
            fi
        else
            echo "❌ Cluster '$cluster_name' not found"
            echo "Available clusters:"
            rosa list clusters
            exit 1
        fi
        
        # Step 2: Get endpoints
        echo ""
        echo "Step 2: Cluster endpoints"
        echo "------------------------"
        api_url=$(get_cluster_api_url "$cluster_name")
        console_url=$(get_cluster_console_url "$cluster_name")
        echo "API URL:     $api_url"
        echo "Console URL: $console_url"
        
        # Step 3: Admin credentials
        echo ""
        echo "Step 3: Admin credentials"
        echo "------------------------"
        if rosa describe admin -c "$cluster_name" &>/dev/null; then
            echo "✅ Admin user exists"
            echo "Get password: rosa describe admin -c $cluster_name"
        else
            echo "⚠️  Creating admin user..."
            rosa create admin -c "$cluster_name"
        fi
        
        # Step 4: Login methods
        echo ""
        echo "Step 4: Login methods"
        echo "--------------------"
        echo "Method 1 - CLI:"
        echo "  oc login $api_url --username cluster-admin"
        echo ""
        echo "Method 2 - Web Console:"
        echo "  1. Open: $console_url"
        echo "  2. Login with cluster-admin"
        echo "  3. Copy login command from web UI"
        echo ""
        echo "Method 3 - Kubeconfig:"
        echo "  rosa download kubeconfig -c $cluster_name"
        
        # Step 5: Verification
        echo ""
        echo "Step 5: Verify connection"
        echo "------------------------"
        if check_cluster_login "$cluster_name"; then
            echo "✅ Already connected to correct cluster"
        else
            echo "⚠️  Please login using one of the methods above"
        fi
        
        # Step 6: Next steps
        echo ""
        echo "Step 6: Next steps"
        echo "-----------------"
        echo "After logging in:"
        echo "1. Verify: oc whoami"
        echo "2. Check nodes: oc get nodes"
        echo "3. Run troubleshooting: ./master-troubleshoot.sh"
        echo "4. Deploy Harness: cd .. && ansible-playbook playbooks/setup-harness.yml -e env=dev"
        ;;
    
    *)
        echo "Invalid option. Please select 1-10."
        exit 1
        ;;
esac

echo ""
echo "🎯 Operation complete!"
echo ""
echo "Useful commands:"
echo "- List clusters: rosa list clusters"
echo "- Cluster details: rosa describe cluster -c CLUSTER_NAME"
echo "- Login help: ./get-cluster-login.sh"
echo "- Troubleshooting: ./master-troubleshoot.sh"
