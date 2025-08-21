# CF-Harness Ansible Role

This Ansible role sets up Harness deployment infrastructure for the CF (ConsultingFirm) application on ROSA clusters.

## Overview

The `cf-harness` role automates:
- Harness CLI installation and configuration
- Harness Delegate deployment on ROSA cluster
- Connector setup (AWS, ECR, GitHub, Kubernetes)
- Service account and RBAC configuration
- Cross-account ECR integration with IRSA

## Prerequisites

1. **ROSA Cluster**: Active ROSA cluster with admin access
2. **AWS Credentials**: Configured for cross-account ECR access
3. **Harness Account**: Active Harness account with:
   - Account ID
   - API Key
   - Delegate token
4. **OpenShift CLI**: `oc` command available
5. **Ansible**: Version 2.9+

## Role Variables

### Required Variables

```yaml
# Harness Configuration
harness_account_id: "YOUR_ACCOUNT_ID"
harness_api_key: "YOUR_API_KEY"
harness_delegate_token: "YOUR_DELEGATE_TOKEN"
harness_org_id: "default"
harness_project_id: "cf-deploy"

# AWS Configuration
aws_account_id_source: "818140567777"  # sidatks account
aws_account_id_target: "606639739464"  # svktek account
aws_region: "us-east-1"
ecr_registry: "818140567777.dkr.ecr.us-east-1.amazonaws.com"

# ROSA Cluster Configuration
rosa_cluster_name: "cf-rosa-cluster"
rosa_cluster_url: "https://api.YOUR_CLUSTER.openshiftapps.com:6443"
rosa_oidc_provider: "oidc.op1.openshiftapps.com/YOUR_ID"

# Environment
environment: "dev"  # dev/test/prod
```

## Usage

### 1. Basic Playbook

```yaml
- hosts: localhost
  gather_facts: yes
  roles:
    - role: cf-harness
      vars:
        harness_account_id: "{{ vault_harness_account_id }}"
        harness_api_key: "{{ vault_harness_api_key }}"
        harness_delegate_token: "{{ vault_harness_delegate_token }}"
        environment: "dev"
```

### 2. Run the Role

```bash
# Full setup
ansible-playbook -i inventory playbooks/setup-harness.yml -e env=dev

# Only CLI setup
ansible-playbook -i inventory playbooks/setup-harness.yml -e env=dev --tags cli

# Only delegate installation
ansible-playbook -i inventory playbooks/setup-harness.yml -e env=dev --tags delegate

# Only connectors
ansible-playbook -i inventory playbooks/setup-harness.yml -e env=dev --tags connectors
```

## Tasks Overview

### 1. CLI Setup (`check_harness_cli.yml`)
- Checks if Harness CLI is installed
- Downloads and installs if missing
- Configures authentication

### 2. Validate Prerequisites (`validate_prerequisites.yml`)
- Verifies OpenShift login
- Checks AWS credentials
- Validates Harness connectivity

### 3. Service Account Setup (`setup_service_accounts.yml`)
- Creates `harness-deployer` service account
- Configures IRSA annotations for ECR access
- Sets up RBAC permissions

### 4. Delegate Installation (`install_delegate.yml`)
- Deploys Harness Delegate to cluster
- Configures cross-account IAM role
- Sets up network policies

### 5. Connector Configuration (`setup_connectors.yml`)
- Creates AWS connector for ECR
- Sets up Kubernetes connector for ROSA
- Configures GitHub connector

### 6. Apply Harness Resources (`apply_harness_resources.yml`)
- Creates service definitions
- Sets up pipelines
- Configures environments

## Directory Structure

```
cf-harness/
├── README.md
├── defaults/
│   └── main.yml              # Default variables
├── vars/
│   └── main.yml              # Role variables
├── tasks/
│   ├── main.yml              # Main task orchestration
│   ├── check_harness_cli.yml # CLI installation
│   ├── validate_prerequisites.yml
│   ├── setup_service_accounts.yml
│   ├── install_delegate.yml
│   ├── setup_connectors.yml
│   └── apply_harness_resources.yml
├── templates/
│   ├── delegate-values.yaml.j2
│   ├── harness-config.yaml.j2
│   └── service-account.yaml.j2
└── files/
    └── install-harness-cli.sh
```

## Harness CLI Manual Setup

If the automated setup fails, manually install Harness CLI:

### macOS
```bash
# Download latest version
curl -LO https://github.com/harness/harness-cli/releases/latest/download/harness-Darwin-arm64
# Or for Intel Macs:
# curl -LO https://github.com/harness/harness-cli/releases/latest/download/harness-Darwin-x86_64

# Make executable
chmod +x harness-Darwin-*

# Move to PATH
sudo mv harness-Darwin-* /usr/local/bin/harness

# Verify installation
harness --version
```

### Linux
```bash
# Download latest version
curl -LO https://github.com/harness/harness-cli/releases/latest/download/harness-Linux-x86_64

# Make executable
chmod +x harness-Linux-x86_64

# Move to PATH
sudo mv harness-Linux-x86_64 /usr/local/bin/harness

# Verify installation
harness --version
```

### Configure CLI
```bash
# Login to Harness
harness login \
  --api-key YOUR_API_KEY \
  --account-id YOUR_ACCOUNT_ID

# Verify configuration
harness account
```

## Security Considerations

1. **Secrets Management**:
   - Store sensitive data in Ansible Vault
   - Never commit API keys or tokens
   - Use environment variables for CI/CD

2. **RBAC**:
   - Delegate uses least privilege principle
   - Service accounts scoped to namespace
   - Cross-account roles with external ID

3. **Network Security**:
   - Network policies restrict pod communication
   - Delegate communicates only with Harness platform
   - ECR access via VPC endpoints

## Troubleshooting

### CLI Issues
```bash
# Check CLI installation
which harness

# Verify API connectivity
curl -H "x-api-key: YOUR_KEY" https://app.harness.io/gateway/api/users/current

# Reset CLI configuration
rm -rf ~/.harness/
harness login --api-key YOUR_KEY --account-id YOUR_ACCOUNT
```

### Delegate Issues
```bash
# Check delegate pods
oc get pods -n harness-delegate-ng

# View delegate logs
oc logs -n harness-delegate-ng deployment/harness-delegate

# Verify delegate registration (Note: CLI doesn't support delegate list)
# Check delegate status in OpenShift
oc get pods -n harness-delegate-ng
```

### Connector Issues
```bash
# Note: The harness CLI v0.0.29 doesn't support test/list commands for connectors
# You can verify connectors in the Harness UI or use the API:

# Check connector via API
curl -H "x-api-key: YOUR_KEY" \
  "https://app.harness.io/gateway/ng/api/connectors/{connector-id}?accountId=YOUR_ACCOUNT"

# List connectors via API
curl -H "x-api-key: YOUR_KEY" \
  "https://app.harness.io/gateway/ng/api/connectors?accountId=YOUR_ACCOUNT"
```

## Support

For issues or questions:
1. Check Harness documentation: https://docs.harness.io
2. Review role execution logs: `ansible-playbook -vvv`
3. Contact Platform Team

## License

Internal use only - ConsultingFirm Platform Team