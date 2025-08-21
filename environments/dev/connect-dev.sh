#!/bin/bash
# ROSA Cluster kubectl configuration for dev
# Generated on: 2025-08-07T20:27:47Z

echo "🔗 Connecting to ROSA cluster: rosa-cluster-dev"
echo "📍 Environment: dev"
echo "🌐 Region: us-east-1"
echo ""

# Get the login command
echo "Getting cluster login command..."
rosa describe cluster -c rosa-cluster-dev | grep "oc login"

echo ""
echo "💡 To configure kubectl access:"
echo "1. Run the 'oc login' command shown above"
echo "2. Or use: rosa login --cluster rosa-cluster-dev"
echo ""
echo "🎯 Console URL: https://console-openshift-console.apps.x3u6j0m9y2e0q8r.wdv8.p1.openshiftapps.com"
echo "🔧 API URL: https://api.x3u6j0m9y2e0q8r.wdv8.p1.openshiftapps.com:6443"
