# Harness Setup Role with REST API Support

This Ansible role sets up Harness for deploying CF microservices to ROSA clusters using REST API for full functionality.

## Features

### API-Based Implementation (Recommended)
- **Full Connector Management**: Create, update, test, and list connectors
- **Complete Resource Control**: Services, environments, infrastructures, pipelines
- **Comprehensive Validation**: Test connections, verify resources, generate reports
- **Cross-Account ECR Access**: IRSA-based authentication for secure registry access
- **Delegate Management**: Deploy and monitor Harness delegates in OpenShift
- **Secret Management**: Handle tokens and credentials securely

### Advantages over CLI
- ✅ Test connector connectivity
- ✅ List all resources (services, environments, pipelines)
- ✅ Detailed error messages and status codes
- ✅ Batch operations support
- ✅ Validation reports with metrics
- ✅ No CLI version dependencies

## Prerequisites

### Required Tools
```bash
# Check prerequisites
ansible --version          # >= 2.9
oc version                  # OpenShift CLI
aws --version              # AWS CLI v2
python3 --version          # >= 3.6
```

### Required Python Packages
```bash
pip install requests        # For API calls
pip install kubernetes      # For K8s operations
pip install boto3          # For AWS operations
```

### Required Access
- Harness account with API key
- OpenShift cluster admin access
- AWS credentials for ECR access
- GitHub token for repository access

## Installation

### 1. Set Environment Variables

Create `environments/dev/vault.yml`:
```yaml
---
# Encrypt with: ansible-vault encrypt environments/dev/vault.yml
vault_harness_account_id: "YOUR_ACCOUNT_ID"
vault_harness_api_key: "YOUR_API_KEY"
vault_harness_delegate_token: "YOUR_DELEGATE_TOKEN"
vault_github_username: "your-github-username"
vault_github_token_ref: "github_pat"
vault_aws_access_key_ref: "aws_access_key"
vault_aws_secret_key_ref: "aws_secret_key"
vault_rosa_cluster_url: "https://api.YOUR_CLUSTER.openshiftapps.com:6443"
vault_rosa_service_account_token_ref: "rosa_sa_token"
```

### 2. Configure Variables

Create `environments/dev/harness-vars.yml`:
```yaml
---
# Harness Configuration
harness_account_id: "{{ vault_harness_account_id }}"
harness_api_key: "{{ vault_harness_api_key }}"
harness_delegate_token: "{{ vault_harness_delegate_token }}"

# Use API instead of CLI (recommended)
use_harness_cli: false
use_harness_api: true

# Connector Configuration
connector_github_id: "github_connector"
connector_github_name: "GitHub Connector"
github_url: "https://github.com"
github_repo: "your-org/your-repo"
github_branch: "main"
github_username: "{{ vault_github_username }}"
github_token_ref: "{{ vault_github_token_ref }}"

connector_aws_ecr_id: "aws_ecr_connector"
connector_aws_ecr_name: "AWS ECR Connector"
cross_account_role_name: "ECRCrossAccountAdmin"
cross_account_external_id: "harness-ecr-{{ environment }}"

connector_rosa_cluster_id: "rosa_cluster_connector"
connector_rosa_cluster_name: "ROSA Cluster Connector"
rosa_service_account_token_ref: "{{ vault_rosa_service_account_token_ref }}"

# Service Configuration
service_identifier: "cf_microservices"
service_name: "CF Microservices"
helm_chart_version: "1.0.0"

# Image Tags
image_tags:
  naming_server: "latest"
  api_gateway: "latest"
  spring_boot_admin: "latest"
  config_service: "latest"
  excel_service: "latest"
  bench_profile: "latest"
  daily_submissions: "latest"
  interviews: "latest"
  placements: "latest"
  frontend: "latest"

# Environment Configuration
environments_list:
  - dev
  - test
  - prod

# Features
enable_delegate_installation: true
enable_connector_creation: true
enable_service_creation: true
enable_pipeline_creation: true
enable_irsa_configuration: true
```

## Usage

### Basic Execution

```bash
# Full setup using API
ansible-playbook playbooks/setup-harness.yml \
  -e env=dev \
  -e aws_profile=sid-KS \
  --ask-vault-pass

# With specific tags
ansible-playbook playbooks/setup-harness.yml \
  -e env=dev \
  --tags connectors,api

# Test mode (check without changes)
ansible-playbook playbooks/setup-harness.yml \
  -e env=dev \
  --check
```

### Available Tags

| Tag | Description |
|-----|-------------|
| `prerequisites` | Validate all prerequisites |
| `service-accounts` | Setup K8s service accounts with IRSA |
| `delegate` | Install Harness delegate |
| `connectors` | Create/update connectors via API |
| `resources` | Create services and environments |
| `pipelines` | Create deployment pipelines |
| `validate` | Run validation tests |
| `api` | All API-based operations |

### Using CLI Instead of API (Limited)

```bash
# Force CLI usage (not recommended)
ansible-playbook playbooks/setup-harness.yml \
  -e env=dev \
  -e use_harness_cli=true \
  -e use_harness_api=false
```

## API Endpoints Used

### Authentication
- `GET /ng/api/user/currentUser` - Verify authentication

### Connectors
- `GET /ng/api/connectors/{id}` - Check connector existence
- `POST /ng/api/connectors` - Create connector
- `PUT /ng/api/connectors/{id}` - Update connector
- `POST /ng/api/connectors/testConnection/{id}` - Test connectivity
- `GET /ng/api/connectors` - List all connectors

### Services
- `GET /ng/api/servicesV2/{id}` - Check service existence
- `POST /ng/api/servicesV2` - Create service
- `PUT /ng/api/servicesV2/{id}` - Update service
- `GET /ng/api/servicesV2` - List all services

### Environments
- `POST /ng/api/environmentsV2` - Create environment
- `GET /ng/api/environmentsV2` - List environments

### Infrastructure
- `POST /ng/api/infrastructures` - Create infrastructure definition

### Pipelines
- `POST /ng/api/pipelines` - Create pipeline
- `GET /ng/api/pipelines` - List pipelines

### Delegates
- `GET /ng/api/delegates` - List and check delegate status

## Validation Features

The API-based validation provides comprehensive checking:

```yaml
# Sample validation report
validation_report:
  timestamp: "2025-01-21T10:30:00Z"
  account_id: "YOUR_ACCOUNT"
  project: "cf-deploy"
  api_authentication: "SUCCESS"
  delegate:
    total: 1
    k8s_ready: 1
  connectors:
    github: "CONNECTED"
    aws_ecr: "CONNECTED"
    rosa_cluster: "CONNECTED"
  resources:
    services: 1
    environments: 3
    pipelines: 1
    secrets: 5
  status: "✅ VALIDATION SUCCESSFUL"
```

## Troubleshooting

### API Authentication Issues
```bash
# Test API key
curl -H "x-api-key: YOUR_KEY" \
  https://app.harness.io/gateway/ng/api/user/currentUser

# Check account access
curl -H "x-api-key: YOUR_KEY" \
  "https://app.harness.io/gateway/ng/api/projects?accountId=YOUR_ACCOUNT"
```

### Connector Test Failures
```bash
# Manual connector test via API
curl -X POST \
  -H "x-api-key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  "https://app.harness.io/gateway/ng/api/connectors/testConnection/CONNECTOR_ID" \
  -d '{
    "accountIdentifier": "YOUR_ACCOUNT",
    "orgIdentifier": "default",
    "projectIdentifier": "cf-deploy"
  }'
```

### Delegate Issues
```bash
# Check delegate in K8s
oc get pods -n harness-delegate-ng
oc logs -n harness-delegate-ng deployment/rosa-harness-delegate

# Check delegate via API
curl -H "x-api-key: YOUR_KEY" \
  "https://app.harness.io/gateway/ng/api/delegates?accountId=YOUR_ACCOUNT"
```

## Advanced Configuration

### Custom API Headers
```yaml
# In your vars file
harness_api_headers:
  x-api-key: "{{ harness_api_key }}"
  Content-Type: "application/json"
  x-harness-account: "{{ harness_account_id }}"
```

### Retry Configuration
```yaml
# In defaults/main.yml
api_request_timeout: 60  # Seconds
max_retries: 5
retry_delay: 15
```

### Validation Report
```yaml
# Enable saving validation report
save_validation_report: true

# Report will be saved to:
# /tmp/harness-validation-report-{timestamp}.yaml
```

## Security Considerations

1. **API Key Management**
   - Always use Ansible Vault for API keys
   - Rotate keys regularly
   - Use service accounts where possible

2. **Network Security**
   - All API calls use HTTPS
   - Certificate validation enabled by default
   - Delegate uses secure WebSocket connection

3. **RBAC**
   - Service accounts with minimal permissions
   - Namespace-scoped access
   - IRSA for cross-account ECR access

## Comparison: API vs CLI

| Feature | API | CLI |
|---------|-----|-----|
| Create Resources | ✅ | ✅ |
| Update Resources | ✅ | ✅ |
| Delete Resources | ✅ | ✅ |
| List Resources | ✅ | ❌ |
| Test Connections | ✅ | ❌ |
| Detailed Errors | ✅ | ❌ |
| Batch Operations | ✅ | ❌ |
| Version Independent | ✅ | ❌ |
| Response Validation | ✅ | Limited |
| Metrics & Reports | ✅ | ❌ |

## Support

For issues or questions:
1. Check API documentation: https://apidocs.harness.io/
2. Review Ansible logs: `ansible-playbook -vvv`
3. Check validation report in `/tmp/`
4. Contact Platform Team

## License

Proprietary - Internal Use Only