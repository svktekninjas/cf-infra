# CF-Harness Ansible Role

Enterprise-grade Ansible role for setting up Harness Platform integration with ROSA (Red Hat OpenShift Service on AWS) clusters for CF workload deployments.

## Overview

This role automates the complete setup of Harness Platform for deploying CF workloads (cf-monitor and cf-deploy) using Helm charts stored in Git repositories, with container images hosted in AWS ECR.

## Features

- **Delegate Management**: Deploys and configures Harness Delegate in ROSA cluster
- **Connector Setup**: Configures Git, AWS, ECR, and Kubernetes connectors
- **Environment Management**: Creates multi-environment setup (dev/staging/prod)
- **Service Configuration**: Sets up Harness services with Helm chart integration
- **Pipeline Automation**: Creates deployment pipelines with approval gates
- **Trigger Configuration**: Sets up Git webhooks and scheduled triggers
- **Security**: Implements secrets management and RBAC
- **Monitoring**: Includes health checks and verification steps

## Requirements

### Software Dependencies
- Ansible >= 2.9
- kubectl
- helm
- Python kubernetes library

### Access Requirements
- Harness Platform account with API access
- ROSA cluster with admin access
- GitHub repositories with appropriate permissions
- AWS ECR access

## Role Structure

```
cf-harness/
├── defaults/main.yml          # Default variables
├── vars/main.yml             # Internal role variables
├── tasks/
│   ├── main.yml              # Main task orchestration
│   ├── validate.yml          # Input validation
│   ├── secrets.yml           # Secrets management
│   ├── delegate.yml          # Delegate deployment
│   ├── connectors.yml        # Connector configuration
│   ├── environments.yml      # Environment setup
│   ├── services.yml          # Service configuration
│   ├── pipelines.yml         # Pipeline creation
│   ├── triggers.yml          # Trigger setup
│   └── verify.yml            # Verification tasks
├── templates/
│   └── verification_report.j2 # Verification report template
├── meta/main.yml             # Role metadata
└── README.md                 # This file
```

## Usage

### Basic Usage

```bash
# Run for development environment
ansible-playbook -i localhost, harness-setup-playbook.yml -e env=dev

# Run for test environment
ansible-playbook -i localhost, harness-setup-playbook.yml -e env=test

# Run for production environment
ansible-playbook -i localhost, harness-setup-playbook.yml -e env=prod
```

### With Vault Encryption

```bash
# Encrypt secrets file
ansible-vault encrypt vault/dev/secrets.yml

# Run with vault password
ansible-playbook -i localhost, harness-setup-playbook.yml -e env=dev --ask-vault-pass
```

### Tag-based Execution

```bash
# Only setup delegate
ansible-playbook harness-setup-playbook.yml -e env=dev --tags delegate

# Only setup connectors
ansible-playbook harness-setup-playbook.yml -e env=dev --tags connectors

# Only verify setup
ansible-playbook harness-setup-playbook.yml -e env=dev --tags verification
```

## Configuration

### Required Variables

Create environment-specific variable files in `environments/{env}/harness-setup.yml`:

```yaml
# Harness Configuration
harness_account_id: "your_account_id"
harness_org_id: "your_org_id"
harness_api_token: "{{ vault_harness_api_token }}"

# ROSA Configuration
rosa_cluster_name: "your-rosa-cluster"

# GitHub Configuration
github_username: "{{ vault_github_username }}"
github_token: "{{ vault_github_token }}"
```

### Vault Secrets

Create encrypted secrets in `vault/{env}/secrets.yml`:

```yaml
vault_harness_api_token: "your_harness_api_token"
vault_github_username: "your_github_username"
vault_github_token: "your_github_token"
```

## Environment-Specific Configurations

### Development
- Single delegate replica
- Minimal resource allocation
- Basic monitoring
- Development branch deployment

### Test
- Dual delegate replicas
- Enhanced testing features
- Staging environment included
- Blue-green deployment strategy

### Production
- Triple delegate replicas
- High availability setup
- Comprehensive monitoring
- Approval gates and compliance features
- Canary deployment strategy

## Outputs

The role generates several output files:

1. **Webhook URLs** (`/tmp/harness-webhook-urls.txt`): GitHub webhook configuration
2. **Verification Report** (`/tmp/harness-verification-report.txt`): Setup verification results
3. **Deployment Summary** (`/tmp/harness-deployment-summary.md`): Complete deployment summary

## Post-Setup Tasks

### 1. Configure GitHub Webhooks
Use the webhook URLs from `/tmp/harness-webhook-urls.txt` to configure webhooks in your GitHub repositories.

### 2. Test Pipeline Execution
- Navigate to Harness UI
- Execute pipelines manually
- Verify deployments in ROSA cluster

### 3. Monitor Delegate Health
```bash
# Check delegate pods
kubectl get pods -n harness-delegate-ng

# View delegate logs
kubectl logs -n harness-delegate-ng -l harness.io/name=cf-harness-delegate-{env}
```

## Troubleshooting

### Common Issues

1. **Delegate Connection Issues**
   - Check network connectivity
   - Verify firewall rules
   - Review delegate logs

2. **ECR Authentication Failures**
   - Verify AWS credentials
   - Check ECR permissions
   - Validate region settings

3. **Git Connector Issues**
   - Confirm GitHub token permissions
   - Verify repository access
   - Check webhook configuration

### Debug Mode

Run with increased verbosity:
```bash
ansible-playbook harness-setup-playbook.yml -e env=dev -vvv
```

## Security Considerations

- Use Ansible Vault for all sensitive data
- Implement least-privilege access
- Regularly rotate secrets
- Enable audit logging
- Review RBAC permissions

## Contributing

1. Follow Ansible best practices
2. Update documentation for new features
3. Test across all environments
4. Maintain backward compatibility

## Support

For issues and questions:
- Check troubleshooting section
- Review Harness documentation
- Consult ROSA documentation
- Check Ansible logs for detailed errors

## License

MIT License - see LICENSE file for details.
