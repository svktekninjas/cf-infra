#!/bin/bash

echo "🧹 Service Account and IAM Cleanup Script"
echo "========================================="

NAMESPACE="harness-delegate-ng"

echo "Current service accounts in $NAMESPACE:"
oc get sa -n $NAMESPACE
echo ""

echo "Current pods and their service accounts:"
oc get pods -n $NAMESPACE -o custom-columns="POD:metadata.name,SERVICE_ACCOUNT:spec.serviceAccountName,STATUS:status.phase"
echo ""

# Analysis and recommendations
echo "📊 ANALYSIS AND RECOMMENDATIONS:"
echo "================================"

echo ""
echo "✅ KEEP THESE SERVICE ACCOUNTS:"
echo "------------------------------"
echo "1. cf-deploy - ✅ KEEP"
echo "   - Currently used by Harness delegate pods"
echo "   - Has proper ECR image pull secrets"
echo "   - Has IRSA annotation (though role doesn't exist)"
echo "   - Labels: app=harness-delegate, environment=dev"

echo ""
echo "2. default - ✅ KEEP"
echo "   - OpenShift default service account"
echo "   - Used by ecr-connectivity-test pod"
echo "   - Required for namespace operations"

echo ""
echo "❌ REMOVE THESE SERVICE ACCOUNTS:"
echo "--------------------------------"
echo "1. builder - ❌ REMOVE"
echo "   - OpenShift build-related service account"
echo "   - Not used by any current pods"
echo "   - Not needed for Harness delegate operations"

echo ""
echo "2. deployer - ❌ REMOVE"
echo "   - OpenShift deployment-related service account"
echo "   - Not used by any current pods"
echo "   - Not needed for Harness delegate operations"

echo ""
echo "3. harness-delegate - ❌ REMOVE"
echo "   - Unused Harness service account"
echo "   - No pods are using it"
echo "   - cf-deploy is the active Harness service account"

echo ""
echo "🔧 IAM ROLES ANALYSIS:"
echo "======================"

echo ""
echo "❌ PROBLEMATIC IAM REFERENCE:"
echo "-----------------------------"
echo "cf-deploy service account references: arn:aws:iam::606639739464:role/HarnessDeployerRole"
echo "❌ This role DOES NOT EXIST - needs to be created or reference removed"

echo ""
echo "✅ EXISTING CLUSTER IAM ROLES (KEEP):"
echo "------------------------------------"
echo "1. rosa-cluster-dev-e7o9-openshift-image-registry-installer-cloud-c"
echo "   - Has ECR-related policy attached"
echo "   - Required for OpenShift image registry operations"

echo ""
echo "2. ManagedOpenShift-Worker-Role"
echo "   - Core ROSA worker node role"
echo "   - Required for cluster operations"

echo ""
echo "🗑️  POTENTIALLY REMOVABLE ECR POLICIES:"
echo "======================================="
echo "These are old CodePipeline ECR policies that may not be needed:"
echo "- CodePipeline-ECRSource-us-east-1-NamingServerCD"
echo "- CodePipeline-ECRSource-us-east-1-ApiGatewayCD"
echo "- CodePipeline-ECRSource-us-east-1-BenchProfilesServiceCD"
echo "- CodePipeline-ECRSource-us-east-1-SpringCloudConfigCD"
echo "- CodePipeline-ECRSource-us-east-1-CommonExcelServiceCD"
echo "- CodePipeline-ECRSource-us-east-1-DailySubmissionCD"
echo "- CodePipeline-ECRSource-us-east-1-PlacmentsServiceCD"
echo "- CodePipeline-ECRSource-us-east-1-ConsultingFirmFrontendCD"
echo "- CodePipeline-ECRSource-us-east-1-InterviewsServiceCD"

echo ""
echo "✅ KEEP THESE ECR POLICIES:"
echo "--------------------------"
echo "- ECRFullAccess - General ECR access policy"
echo "- UserECRFullAccess - User-specific ECR access"
echo "- UserECRReadOnly - Read-only ECR access"

echo ""
read -p "Do you want to proceed with cleanup? (y/N): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    echo ""
    echo "🧹 Starting cleanup..."
    
    # Remove unused service accounts
    echo "1. Removing unused service accounts..."
    
    echo "Removing builder service account..."
    oc delete sa builder -n $NAMESPACE --ignore-not-found=true
    
    echo "Removing deployer service account..."
    oc delete sa deployer -n $NAMESPACE --ignore-not-found=true
    
    echo "Removing unused harness-delegate service account..."
    oc delete sa harness-delegate -n $NAMESPACE --ignore-not-found=true
    
    echo ""
    echo "2. Fixing cf-deploy service account IRSA annotation..."
    
    # Remove the non-existent role annotation
    oc annotate sa cf-deploy -n $NAMESPACE eks.amazonaws.com/role-arn- || echo "Annotation not found"
    
    echo ""
    echo "3. Verifying cleanup..."
    echo "Remaining service accounts:"
    oc get sa -n $NAMESPACE
    
    echo ""
    echo "✅ Service account cleanup complete!"
    echo ""
    echo "📋 NEXT STEPS:"
    echo "=============="
    echo "1. Create proper IRSA role for cf-deploy service account"
    echo "2. Add ECR permissions to the new role"
    echo "3. Update cf-deploy service account with correct role ARN"
    echo "4. Review and remove old CodePipeline ECR policies if not needed"
    echo ""
    echo "To create proper IRSA setup, run:"
    echo "./master-troubleshoot.sh and select option 8 (Setup IRSA)"
    
else
    echo ""
    echo "❌ Cleanup cancelled. No changes made."
fi

echo ""
echo "📊 SUMMARY OF WHAT NEEDS ECR ACCESS:"
echo "==================================="
echo "For Harness delegate ECR image pulling, you need:"
echo ""
echo "1. ✅ cf-deploy service account (keep and fix)"
echo "   - Add proper IRSA role with ECR permissions"
echo "   - Keep ECR image pull secrets"
echo ""
echo "2. ✅ Cluster IAM roles (already have some ECR access)"
echo "   - rosa-cluster-dev-e7o9-openshift-image-registry-installer-cloud-c"
echo "   - ManagedOpenShift-Worker-Role"
echo ""
echo "3. ❌ Remove unused service accounts (builder, deployer, harness-delegate)"
echo "   - They don't need ECR access"
echo "   - They're not being used"
echo ""
echo "4. 🔍 Review old CodePipeline ECR policies"
echo "   - Determine if still needed for CI/CD pipelines"
echo "   - Remove if no longer used"
