#!/bin/bash

echo "🔗 ROSA Cluster Login Helper"
echo "==========================="

CLUSTER_NAME="rosa-cluster-dev"

echo "Getting current cluster information for: $CLUSTER_NAME"
echo ""

# Check if ROSA CLI is available
if ! command -v rosa &> /dev/null; then
    echo "❌ ROSA CLI not found. Please install it first."
    exit 1
fi

# Get cluster details
echo "1. Fetching cluster details..."
CLUSTER_INFO=$(rosa describe cluster -c $CLUSTER_NAME 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "❌ Could not find cluster '$CLUSTER_NAME'"
    echo ""
    echo "Available clusters:"
    rosa list clusters
    exit 1
fi

# Extract API URL
API_URL=$(echo "$CLUSTER_INFO" | grep "API URL:" | awk '{print $3}')
CONSOLE_URL=$(echo "$CLUSTER_INFO" | grep "Console URL:" | awk '{print $3}')
CLUSTER_STATE=$(echo "$CLUSTER_INFO" | grep "State:" | awk '{print $2}')

echo "✅ Cluster found!"
echo "   Name: $CLUSTER_NAME"
echo "   State: $CLUSTER_STATE"
echo "   API URL: $API_URL"
echo "   Console URL: $CONSOLE_URL"
echo ""

if [ "$CLUSTER_STATE" != "ready" ]; then
    echo "⚠️  Cluster is not in 'ready' state. Current state: $CLUSTER_STATE"
    echo "Please wait for cluster to be ready before attempting login."
    exit 1
fi

# Check for existing admin user
echo "2. Checking admin credentials..."
ADMIN_INFO=$(rosa describe admin -c $CLUSTER_NAME 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ Admin user exists"
    echo ""
    echo "🔑 Login Command:"
    echo "oc login $API_URL --username cluster-admin"
    echo ""
    echo "If you need the password, check your cluster documentation or:"
    echo "rosa describe admin -c $CLUSTER_NAME"
else
    echo "⚠️  No admin user found. Creating one..."
    rosa create admin -c $CLUSTER_NAME
    
    if [ $? -eq 0 ]; then
        echo "✅ Admin user created"
        echo ""
        echo "🔑 Login Command:"
        echo "oc login $API_URL --username cluster-admin"
        echo ""
        echo "Use the password provided above."
    else
        echo "❌ Failed to create admin user"
        exit 1
    fi
fi

echo ""
echo "🌐 Alternative Access Methods:"
echo ""
echo "1. Web Console:"
echo "   $CONSOLE_URL"
echo ""
echo "2. Get login token from web console:"
echo "   - Login to web console"
echo "   - Click your username (top right)"
echo "   - Select 'Copy login command'"
echo "   - Use the provided oc login command"
echo ""
echo "3. Using kubeconfig:"
echo "   rosa download kubeconfig -c $CLUSTER_NAME"
echo ""

# Test current connection
echo "3. Testing current connection..."
if oc whoami &>/dev/null; then
    CURRENT_USER=$(oc whoami)
    CURRENT_SERVER=$(oc whoami --show-server)
    echo "✅ Already logged in as: $CURRENT_USER"
    echo "   Server: $CURRENT_SERVER"
    
    if [ "$CURRENT_SERVER" = "$API_URL" ]; then
        echo "✅ Connected to the correct cluster"
    else
        echo "⚠️  Connected to different cluster. Please login to:"
        echo "   $API_URL"
    fi
else
    echo "❌ Not currently logged in to any cluster"
    echo ""
    echo "To login, run:"
    echo "oc login $API_URL --username cluster-admin"
fi

echo ""
echo "🎯 Next Steps:"
echo "1. Login using the command above"
echo "2. Verify access: oc whoami"
echo "3. Run troubleshooting: ./master-troubleshoot.sh"
