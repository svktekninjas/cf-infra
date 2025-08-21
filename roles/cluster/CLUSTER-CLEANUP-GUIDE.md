# ROSA Cluster Cleanup Guide

## Overview
This guide provides instructions for safely cleaning up ROSA clusters and all associated AWS resources.

## ⚠️ WARNING
**Cluster deletion is IRREVERSIBLE!** All data, applications, and configurations will be permanently lost.

## Resources That Will Be Deleted

### Core ROSA Resources
- ROSA cluster (control plane, compute nodes)
- All workloads and applications running on the cluster
- Persistent volumes and data

### AWS Infrastructure
- **EC2 Resources:**
  - Master nodes (control plane)
  - Worker nodes
  - Infrastructure nodes
  - Security groups
  - Key pairs (if cluster-managed)

- **Networking:**
  - Load balancers (ALB, NLB)
  - NAT Gateways
  - Elastic IPs
  - Internet Gateways
  - VPC and Subnets (optional, if cluster-owned)
  - Route tables

- **IAM Resources:**
  - Operator IAM roles
  - Instance IAM roles
  - OIDC provider
  - Policies and role attachments

- **Storage:**
  - S3 buckets (image registry)
  - EBS volumes
  - Snapshots

## Cleanup Methods

### Method 1: Using the Cleanup Playbook (Recommended)

```bash
# Basic cleanup (retains VPC)
ansible-playbook playbooks/cleanup_cluster.yml \
  -e "target_environment=dev" \
  -e "aws_profile=sid-KS"

# Cleanup including VPC (if cluster-owned)
ansible-playbook playbooks/cleanup_cluster.yml \
  -e "target_environment=dev" \
  -e "aws_profile=sid-KS" \
  -e "delete_cluster_vpc=true"

# Cleanup specific cluster by name
ansible-playbook playbooks/cleanup_cluster.yml \
  -e "cluster_name=rosa-cluster-dev" \
  -e "aws_profile=sid-KS" \
  -e "aws_region=us-east-1"
```

### Method 2: Using Main Playbook with Cleanup Flag

```bash
# Run cleanup through main playbook
ansible-playbook playbooks/main.yml \
  --tags cluster-cleanup \
  -e "target_environment=dev" \
  -e "aws_profile=sid-KS" \
  -e "cluster_cleanup=true"
```

### Method 3: Manual ROSA CLI Cleanup

```bash
# Set AWS profile
export AWS_PROFILE=sid-KS

# Delete cluster (will handle most resources)
rosa delete cluster -c rosa-cluster-dev --yes --watch

# Delete operator roles
rosa delete operator-roles -c rosa-cluster-dev --yes

# Delete OIDC provider
rosa delete oidc-provider -c rosa-cluster-dev --yes
```

## Pre-Cleanup Checklist

1. **Backup Important Data**
   - Export any important configurations
   - Backup persistent volume data
   - Save any custom resources or CRDs

2. **Document Current State**
   ```bash
   # Save cluster information
   rosa describe cluster -c rosa-cluster-dev > cluster-backup.txt
   
   # List all resources
   kubectl get all --all-namespaces > resources-backup.txt
   ```

3. **Verify Cluster to Delete**
   ```bash
   # List all clusters
   rosa list clusters
   
   # Verify cluster details
   rosa describe cluster -c rosa-cluster-dev
   ```

## Cleanup Process Flow

1. **Safety Checks**
   - Confirms cluster name
   - Requires explicit confirmation
   - Shows resources to be deleted

2. **ROSA Cluster Deletion**
   - Initiates ROSA cluster deletion
   - Waits for cluster removal
   - Monitors deletion progress

3. **IAM Cleanup**
   - Removes operator roles
   - Deletes OIDC provider
   - Cleans up policies

4. **Infrastructure Cleanup**
   - Removes load balancers
   - Deletes security groups
   - Cleans up networking (optional)

5. **Verification**
   - Confirms all resources deleted
   - Reports cleanup status

## Variables and Options

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `target_environment` | Environment to clean up (dev/test/prod) | - | Yes* |
| `cluster_name` | Specific cluster name to delete | - | Yes* |
| `aws_profile` | AWS profile to use | - | Yes |
| `aws_region` | AWS region | us-east-1 | No |
| `delete_cluster_vpc` | Delete VPC and networking | false | No |
| `cluster_cleanup` | Enable cleanup mode | false | No |

*Either `target_environment` or `cluster_name` must be provided

## Post-Cleanup Verification

### AWS Console Checks
1. **EC2 Dashboard**
   - Verify no running instances with cluster tags
   - Check security groups are removed
   - Confirm load balancers are deleted

2. **VPC Dashboard**
   - Verify NAT Gateways are deleted
   - Check if VPC is removed (if requested)
   - Confirm route tables are cleaned

3. **IAM Dashboard**
   - Verify operator roles are deleted
   - Check OIDC provider is removed

### CLI Verification
```bash
# Verify cluster is deleted
rosa list clusters

# Check for remaining EC2 instances
aws ec2 describe-instances --filters "Name=tag:red-hat-clustertype,Values=rosa"

# Check for remaining load balancers
aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'rosa-cluster')]"

# Check IAM roles
aws iam list-roles --query "Roles[?contains(RoleName, 'rosa-cluster')]"
```

## Troubleshooting

### Cluster Deletion Stuck
```bash
# Force delete if stuck
rosa delete cluster -c rosa-cluster-dev --yes

# Check deletion status
rosa describe cluster -c rosa-cluster-dev
```

### Orphaned Resources
If resources remain after cleanup:

1. **Security Groups with Dependencies**
   ```bash
   # Find dependencies
   aws ec2 describe-security-groups --group-ids sg-xxxxx
   
   # Remove rules first
   aws ec2 revoke-security-group-ingress --group-id sg-xxxxx --protocol all --source-group sg-yyyyy
   
   # Then delete
   aws ec2 delete-security-group --group-id sg-xxxxx
   ```

2. **VPC Won't Delete**
   ```bash
   # Check for remaining ENIs
   aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=vpc-xxxxx"
   
   # Delete ENIs if found
   aws ec2 delete-network-interface --network-interface-id eni-xxxxx
   ```

## Recovery Options

If cleanup was accidental:
- **Immediately**: Stop the cleanup process (Ctrl+C)
- **Partial Deletion**: Some resources may be recoverable from AWS backups
- **Complete Deletion**: Restore from backups if available

## Best Practices

1. **Always verify** cluster name before deletion
2. **Take backups** before cleanup
3. **Use test environment** first
4. **Document** what was deleted
5. **Verify cleanup** in AWS Console
6. **Keep VPC** if shared with other resources

## Support

For issues with cleanup:
1. Check CloudTrail logs for deletion events
2. Review Ansible playbook output
3. Manually remove stuck resources via AWS Console
4. Contact Red Hat support for ROSA-specific issues