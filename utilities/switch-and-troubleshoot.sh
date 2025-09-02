#!/bin/bash

echo "🔄 Current Cluster Connection and Troubleshooting"
echo "================================================="

# Get current cluster connection dynamically
CURRENT_API=$(oc whoami --show-server 2>/dev/null)
CURRENT_USER=$(oc whoami 2>/dev/null)

echo "Current connection status:"
if [ "$CURRENT_API" != "" ] && [ "$CURRENT_USER" != "" ]; then
    echo "  Server: $CURRENT_API"
    echo "  User: $CURRENT_USER"
    echo "✅ Connected to cluster"
else
    echo "  ❌ Not connected to any cluster"
    echo ""
    echo "Please login to your cluster first:"
    echo "oc login YOUR_CLUSTER_API_URL --username cluster-admin"
    exit 1
fi

echo ""
echo "🔍 Verifying connection..."
echo "Current server: $(oc whoami --show-server)"
echo "Current user: $(oc whoami)"
echo "Cluster access: $(oc auth can-i '*' '*' --all-namespaces && echo 'Full admin access' || echo 'Limited access')"

echo ""
echo "🚀 Now running master troubleshooting..."
echo "======================================="

# Run the master troubleshoot script
./master-troubleshoot.sh
