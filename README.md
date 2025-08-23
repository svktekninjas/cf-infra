# ROSA Infrastructure Ansible Automation

## 🚀 Overview

This repository contains comprehensive Ansible automation for deploying and managing Red Hat OpenShift Service on AWS (ROSA) infrastructure with complete microservices deployment capabilities. The automation covers the entire lifecycle from AWS setup, ROSA cluster provisioning, database infrastructure, monitoring stack, to full microservices deployment using Helm charts.

## 📁 Complete Repository Structure

```
ansible/
├── .github/
│   └── workflows/
│       └── ansible-ci.yml              # CI/CD pipeline for code quality and security
├── environments/                       # Environment-specific configurations
│   ├── dev/
│   │   ├── cf-db.yml                  # Database configuration for dev
│   │   ├── cf-deployment.yml          # Microservices deployment config
│   │   ├── cluster-config.yml         # ROSA cluster configuration
│   │   ├── deployment-values.yaml     # Helm values for microservices
│   │   ├── dev.yml                    # Main dev environment variables
│   │   ├── harness-vars.yml           # Harness delegate configuration
│   │   ├── monitoring-config.yml      # Prometheus/Grafana config
│   │   └── routes-config.yml          # OpenShift routes configuration
│   ├── test/                          # Test environment (similar structure)
│   └── prod/                          # Production environment (similar structure)
├── playbooks/
│   ├── main.yml                       # Master playbook orchestrating all roles
│   ├── cf-deployment.yml              # Microservices deployment playbook
│   ├── cleanup_cluster.yml           # Cluster cleanup playbook
│   ├── deployment.yml                 # Alternative deployment playbook
│   └── setup-harness.yml             # Harness delegate setup
├── roles/
│   ├── aws-setup/                    # AWS CLI and environment setup
│   │   ├── defaults/main.yml         # Default variables
│   │   ├── meta/main.yml             # Role metadata
│   │   ├── tasks/
│   │   │   ├── main.yml              # Main task orchestration
│   │   │   ├── install_aws_cli.yml   # AWS CLI installation
│   │   │   ├── setup_environment.yml # Environment configuration
│   │   │   ├── enable_rosa_service.yml # Enable ROSA in AWS
│   │   │   └── validate_service_account.yml # AWS validation
│   │   └── templates/                # Jinja2 templates for env files
│   ├── rosa-cli/                     # ROSA CLI setup and configuration
│   │   ├── tasks/
│   │   │   ├── main.yml              # Main task orchestration
│   │   │   ├── check_install_rosa_cli.yml # ROSA CLI installation
│   │   │   ├── rosa_authentication.yml # Authentication setup
│   │   │   └── configure_environment.yml # Environment configuration
│   │   └── meta/main.yml             # Role metadata with platforms
│   ├── cluster/                      # ROSA cluster management
│   │   ├── tasks/
│   │   │   ├── main.yml              # Cluster orchestration
│   │   │   ├── check_existing_cluster.yml # Check for existing clusters
│   │   │   ├── create_rosa_cluster.yml # Create new ROSA cluster
│   │   │   ├── create_account_roles.yml # AWS IAM roles for ROSA
│   │   │   ├── create_oidc_configuration.yml # OIDC provider setup
│   │   │   ├── configure_cluster_access.yml # Admin users and access
│   │   │   ├── monitor_cluster_status.yml # Health monitoring
│   │   │   ├── update_cluster_environment.yml # Environment updates
│   │   │   ├── apply_resource_tags.yml # AWS resource tagging
│   │   │   ├── apply_openshift_labels.yml # OpenShift labels
│   │   │   └── cluster_cleanup_simple.yml # Cleanup tasks
│   │   └── vars/
│   │       └── cluster-variables.yml # Cluster-specific variables
│   ├── cf-db/                        # Aurora PostgreSQL database setup
│   │   ├── tasks/
│   │   │   ├── main.yml              # Database orchestration
│   │   │   ├── create_vpc.yml        # VPC creation for database
│   │   │   ├── private_subnets.yml   # Private subnet configuration
│   │   │   ├── nat_gateway.yml       # NAT gateway for outbound
│   │   │   ├── security_groups.yml   # Security group rules
│   │   │   ├── aurora_cluster.yml    # Aurora cluster creation
│   │   │   ├── db_cluster.yml        # Database cluster config
│   │   │   ├── networking.yml        # Network configuration
│   │   │   ├── nw_connectivity.yml   # VPC peering setup
│   │   │   ├── security.yml          # Security configurations
│   │   │   └── db_cleanup.yml        # Database cleanup tasks
│   │   └── docs/                     # Extensive documentation
│   ├── cf-deployment/                # Microservices deployment
│   │   ├── tasks/
│   │   │   ├── main.yml              # Deployment orchestration
│   │   │   ├── cf-namespace.yml      # Namespace creation
│   │   │   ├── cf-microservices.yml  # Helm chart deployment
│   │   │   ├── ecr-token-management.yml # ECR authentication
│   │   │   └── harness-delegate.yml  # Harness CI/CD setup
│   │   └── defaults/main.yml         # Deployment defaults
│   ├── cf-harness/                   # Harness integration
│   │   ├── tasks/
│   │   │   ├── main.yml              # Harness orchestration
│   │   │   ├── install_delegate.yml  # Delegate installation
│   │   │   ├── setup_connectors.yml  # Connector configuration
│   │   │   ├── setup_connectors_api.yml # API-based setup
│   │   │   ├── validate_installation.yml # Installation validation
│   │   │   └── apply_harness_resources.yml # Resource application
│   │   └── templates/                # Harness YAML templates
│   ├── monitoring/                   # Prometheus/Grafana stack
│   │   ├── tasks/
│   │   │   ├── main.yml              # Monitoring orchestration
│   │   │   ├── create_monitoring_namespace.yml # Namespace setup
│   │   │   ├── deploy_prometheus.yml # Prometheus deployment
│   │   │   ├── deploy_grafana.yml    # Grafana deployment
│   │   │   ├── deploy_node_exporter.yml # Node metrics
│   │   │   ├── configure_monitoring_rbac.yml # RBAC setup
│   │   │   ├── configure_service_monitors.yml # Service discovery
│   │   │   ├── setup_grafana_dashboards.yml # Dashboard import
│   │   │   └── validate_monitoring_setup.yml # Validation
│   │   └── vars/
│   │       └── monitoring-variables.yml # Monitoring configs
│   ├── routes/                       # OpenShift route management
│   │   ├── tasks/
│   │   │   ├── main.yml              # Route orchestration
│   │   │   ├── create_apigateway_route.yml # API Gateway route
│   │   │   ├── create_frontend_service_route.yml # Frontend route
│   │   │   ├── create_grafana_route.yml # Grafana external access
│   │   │   ├── create_prometheus_route.yml # Prometheus access
│   │   │   ├── validate_routes.yml   # Route validation
│   │   │   └── validate_cf_dev_routes.yml # Dev route checks
│   │   └── vars/
│   │       └── routes-variables.yml  # Route configurations
│   └── validation/                   # Infrastructure validation
│       └── tasks/
│           ├── main.yml              # Validation orchestration
│           ├── validate_aws_region.yml # AWS region checks
│           ├── validate_aws_quotas.yml # Service quota validation
│           ├── validate_availability_zones.yml # AZ validation
│           ├── validate_cluster_config.yml # Cluster validation
│           ├── validate_rosa_prerequisites.yml # ROSA checks
│           └── validate_autoscaling_config.yml # Autoscaling
├── MAKE/                             # Advanced Makefile tools
│   ├── Makefile                      # Main automation makefile
│   ├── .ansible-lint                 # Ansible lint configuration
│   └── .yamllint                     # YAML lint configuration
├── scripts/                          # Utility scripts
├── venv/                             # Python virtual environment
├── .ansible-lint                     # Project ansible-lint config
├── .yamllint                         # Project YAML lint config
├── .gitignore                        # Git ignore rules
├── ansible.cfg                       # Ansible configuration
├── inventory                         # Ansible inventory
├── requirements.txt                  # Python dependencies
├── requirements-dev.txt              # Development dependencies
├── CLAUDE.md                         # AI assistant instructions
├── GITHUB_SETTINGS.md                # GitHub repository setup
└── README.md                         # This file
```

## 🔑 Key Components Explained

### **Environments Directory**
Contains all environment-specific configurations:
- **dev/test/prod**: Separate configurations for each environment
- **deployment-values.yaml**: Helm chart values for microservices
- **cluster-config.yml**: ROSA cluster specifications
- **cf-db.yml**: Aurora database configurations
- **monitoring-config.yml**: Observability stack settings

### **Roles Directory**
Modular Ansible roles for specific functions:
- **aws-setup**: Foundational AWS CLI and environment setup
- **rosa-cli**: ROSA CLI installation and authentication
- **cluster**: Complete ROSA cluster lifecycle management
- **cf-db**: Aurora PostgreSQL with VPC peering to ROSA
- **cf-deployment**: Microservices deployment using Helm
- **cf-harness**: CI/CD integration with Harness
- **monitoring**: Full observability stack (Prometheus/Grafana)
- **routes**: OpenShift route management for external access
- **validation**: Pre-flight checks and validation

### **MAKE Directory**
Advanced automation tools:
- Comprehensive Makefile for linting and validation
- Pre-configured ansible-lint and yamllint settings
- Automated fixes for common issues

## 🎯 Prerequisites

### System Requirements
- **Operating System**: Linux/macOS (Ubuntu 20.04+, RHEL 8+, macOS 11+)
- **Ansible**: Version 11.5.0+ (includes ansible-core 2.18.x)
- **Python**: 3.9+ with pip
- **Tools**: git, curl, unzip, make
- **Memory**: Minimum 8GB RAM
- **Storage**: 20GB free space

### Account Requirements
- **AWS Account**: With appropriate IAM permissions
- **Red Hat Account**: With ROSA subscription
- **Container Registry**: Access to ECR or Docker Hub
- **GitHub Account**: For CI/CD integration (optional)

### Required Permissions
#### AWS IAM Permissions:
- ROSA service permissions
- VPC and networking management
- RDS/Aurora database creation
- IAM role creation
- CloudWatch access

#### OpenShift Permissions:
- Cluster admin access
- Namespace creation
- Route management
- RBAC configuration

## 📦 Installation

### 1. Clone Repository
```bash
git clone https://github.com/svktekninjas/cf-infra.git
cd cf-infra/ansible
```

### 2. Set Up Python Environment
```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# For development
pip install -r requirements-dev.txt
```

### 3. Configure AWS Credentials
```bash
# Configure AWS CLI
aws configure --profile sid-KS

# Or export environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 4. Obtain ROSA Token
```bash
# Get token from Red Hat console
# Visit: https://console.redhat.com/openshift/token/rosa
export ROSA_TOKEN="sha256~your-token-here"
```

## 🚀 Execution Guide

### Complete Infrastructure Setup

#### 1. Full Stack Deployment (Recommended)
```bash
# Deploy complete infrastructure for dev environment
ansible-playbook playbooks/main.yml \
  -e "target_environment=dev" \
  -e "aws_profile=sid-KS"

# For test environment
ansible-playbook playbooks/main.yml \
  -e "target_environment=test" \
  -e "aws_profile=sid-KS-test"

# For production
ansible-playbook playbooks/main.yml \
  -e "target_environment=prod" \
  -e "aws_profile=sid-KS-prod"
```

### Individual Component Deployment

#### 2. AWS Setup Only
```bash
# Install AWS CLI and configure environment
ansible-playbook playbooks/main.yml \
  --tags aws-setup \
  -e "target_environment=dev" \
  -e "aws_profile=sid-KS"
```

#### 3. ROSA CLI Setup Only
```bash
# Install ROSA CLI and authenticate
ansible-playbook playbooks/main.yml \
  --tags rosa-cli \
  -e "target_environment=dev" \
  -e "aws_profile=sid-KS"
```

#### 4. ROSA Cluster Creation
```bash
# Create ROSA cluster
ansible-playbook playbooks/main.yml \
  --tags cluster \
  -e "target_environment=dev" \
  -e "aws_profile=sid-KS" \
  -e "cluster_name=cf-rosa-dev"
```

#### 5. Database Infrastructure
```bash
# Deploy Aurora PostgreSQL
ansible-playbook playbooks/main.yml \
  --tags cf-db \
  -e "target_environment=dev" \
  -e "aws_profile=sid-KS"
```

#### 6. Microservices Deployment
```bash
# Deploy all microservices
ansible-playbook playbooks/main.yml \
  --tags cf-deployment \
  -e "target_environment=dev" \
  -e "aws_profile=sid-KS"

# Deploy specific service only
ansible-playbook playbooks/main.yml \
  --tags cf-deployment \
  -e "target_environment=dev" \
  -e "deploy_api_gateway_only=true"
```

#### 7. Monitoring Stack
```bash
# Deploy Prometheus and Grafana
ansible-playbook playbooks/main.yml \
  --tags monitoring \
  -e "target_environment=dev" \
  -e "aws_profile=sid-KS"
```

#### 8. Routes Configuration
```bash
# Configure external routes
ansible-playbook playbooks/main.yml \
  --tags routes \
  -e "target_environment=dev" \
  -e "aws_profile=sid-KS"
```

### Advanced Execution Options

#### Dry Run (Check Mode)
```bash
# Test without making changes
ansible-playbook playbooks/main.yml \
  --check --diff \
  -e "target_environment=dev" \
  -e "aws_profile=sid-KS"
```

#### Verbose Output
```bash
# Run with detailed output
ansible-playbook playbooks/main.yml \
  -vvv \
  -e "target_environment=dev" \
  -e "aws_profile=sid-KS"
```

#### Skip Specific Roles
```bash
# Skip validation checks
ansible-playbook playbooks/main.yml \
  --skip-tags validation \
  -e "target_environment=dev"
```

#### Parallel Execution
```bash
# Run with multiple forks for speed
ansible-playbook playbooks/main.yml \
  --forks 10 \
  -e "target_environment=dev"
```

## 🔧 Makefile Commands

The project includes a comprehensive Makefile for maintenance:

```bash
# Install all dependencies
make install

# Run all linters
make lint

# Run YAML lint with auto-fix
make fix

# Run ansible-lint
make ansible-lint

# Validate specific path
make validate-path PATH=/path/to/check

# Run security scan
make security-scan

# Check for secrets
make check-secrets

# Full validation suite
make validate

# Clean up temporary files
make clean
```

## 📊 Microservices Architecture

The deployment includes a complete Spring Boot microservices ecosystem:

### Core Services
- **Naming Server** (Eureka): Service discovery on port 8761
- **API Gateway**: Central routing and authentication on port 8765
- **Config Service**: Centralized configuration on port 8888
- **Spring Boot Admin**: Service monitoring on port 8082

### Business Services
- **Bench Profile Service**: Port 8081
- **Excel Service**: Port 8083
- **Daily Submissions**: Port 8084
- **Placements**: Port 8085
- **Interviews**: Port 8086
- **Frontend**: React application on port 3000

## 🔒 Security Features

### Secret Management
- Ansible Vault for sensitive data
- AWS Secrets Manager integration
- Kubernetes secrets for applications
- ECR token auto-rotation

### Network Security
- Private subnets for databases
- VPC peering for secure communication
- Security groups with least privilege
- Network policies in OpenShift

### Compliance
- YAML and Ansible linting
- Security scanning with Trivy
- Secret detection with detect-secrets
- Automated compliance checks in CI/CD

## 🐛 Troubleshooting

### Common Issues and Solutions

#### 1. ROSA Authentication Fails
```bash
# Verify token
rosa whoami

# Get new token
rosa login --token=$(cat ~/.rosa/token)

# Check token expiry
rosa token-info
```

#### 2. Database Connection Issues
```bash
# Check VPC peering
aws ec2 describe-vpc-peering-connections \
  --filters "Name=status-code,Values=active"

# Verify security groups
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx
```

#### 3. Microservices Not Starting
```bash
# Check pod status
oc get pods -n cf-dev

# View pod logs
oc logs -f deployment/api-gateway -n cf-dev

# Check resource quotas
oc describe resourcequota -n cf-dev
```

#### 4. ECR Authentication Issues
```bash
# Manually refresh ECR token
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  818140567777.dkr.ecr.us-east-1.amazonaws.com

# Check secret
oc get secret ecr-secret -n cf-dev -o yaml
```

### Debug Commands
```bash
# Check cluster status
rosa describe cluster -c cf-rosa-dev

# View all resources in namespace
oc get all -n cf-dev

# Check route status
oc get routes -n cf-dev

# Monitor cluster events
oc get events -n cf-dev --sort-by='.lastTimestamp'
```

## 📈 Monitoring and Observability

### Prometheus Metrics
- Cluster metrics: CPU, memory, network
- Application metrics: JVM, HTTP requests
- Custom metrics: Business KPIs

### Grafana Dashboards
- Cluster overview dashboard
- Application performance dashboard
- Database monitoring dashboard
- Custom business dashboards

### Access Monitoring Tools
```bash
# Get Grafana URL
oc get route grafana -n monitoring

# Get Prometheus URL
oc get route prometheus -n monitoring

# Default credentials
# Username: admin
# Password: (check secret or use configured value)
```

## 🔄 CI/CD Integration

### GitHub Actions
The repository includes a complete CI/CD pipeline:
- YAML validation
- Ansible linting
- Security scanning
- Automated testing
- Deployment automation

### Harness Integration
- Automated delegate installation
- Pipeline templates
- GitOps workflows
- Continuous verification

## 📝 Environment Variables

### Required Variables
```bash
# AWS Configuration
export AWS_PROFILE="sid-KS"
export AWS_REGION="us-east-1"

# ROSA Configuration
export ROSA_TOKEN="sha256~your-token"
export CLUSTER_NAME="cf-rosa-dev"

# Application Configuration
export TARGET_ENVIRONMENT="dev"
export DEPLOY_NAMESPACE="cf-dev"
```

### Optional Variables
```bash
# Helm Configuration
export HELM_TIMEOUT="600"
export HELM_WAIT="true"

# Monitoring
export GRAFANA_ADMIN_PASSWORD="secure-password"
export PROMETHEUS_RETENTION="30d"

# Database
export DB_MASTER_PASSWORD="secure-password"
export DB_BACKUP_RETENTION="7"
```

## 🤝 Contributing

### Development Workflow
1. Create feature branch
2. Make changes following existing patterns
3. Run linting: `make lint`
4. Test changes: `ansible-playbook --check`
5. Create pull request

### Code Standards
- Follow Ansible best practices
- Use FQCN for module names
- Add comprehensive documentation
- Include error handling
- Write idempotent tasks

## 📚 Additional Resources

### Documentation
- [Ansible Documentation](https://docs.ansible.com/)
- [ROSA Documentation](https://docs.openshift.com/rosa/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

### Support
- GitHub Issues: Report bugs and request features
- Documentation: Check `docs/` directory for detailed guides
- Logs: Review `logs/` directory for execution history

## 📄 License

This project is licensed under the MIT License. See LICENSE file for details.

---

## 🚀 Quick Start Commands

```bash
# Complete setup for dev
ansible-playbook playbooks/main.yml \
  -e "target_environment=dev" \
  -e "aws_profile=sid-KS"

# Validate everything
make validate-path PATH=/Users/swaroop/SIDKS/ansible

# Deploy microservices only
ansible-playbook playbooks/main.yml \
  --tags cf-deployment \
  -e "target_environment=dev"

# Clean up cluster
ansible-playbook playbooks/cleanup_cluster.yml \
  -e "target_environment=dev" \
  -e "cluster_name=cf-rosa-dev"
```

This automation provides a production-ready, enterprise-grade solution for complete ROSA infrastructure and microservices deployment with comprehensive monitoring, security, and operational capabilities.