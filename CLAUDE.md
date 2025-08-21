# CLAUDE.md
# ZERO HALLUCINATION POLICY
ALWAYS verify claims with actual evidence before responding. NEVER speculate or make assumptions. If you cannot verify something with tools, say "I need to check" and then check. DO NOT agree with user hypotheses without verification. DO NOT use phrases like "You're right", "That's likely", "probably", or "might be" without concrete evidence. Either show proof from actual tool outputs or explicitly state "I cannot determine this without checking [specific thing]". When the user suggests a cause, treat it as a hypothesis to test, not a fact to accept.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Commands

### Ansible Playbook Execution
```bash
# Complete ROSA infrastructure setup (all roles)
ansible-playbook playbooks/main.yml -e "target_environment=dev" -e "aws_profile=sid-KS"
ansible-playbook playbooks/main.yml -e "target_environment=test" -e "aws_profile=sid-KS-test"
ansible-playbook playbooks/main.yml -e "target_environment=prod" -e "aws_profile=sid-KS-prod"

# Execute specific roles with tags
ansible-playbook playbooks/main.yml --tags aws-setup -e "target_environment=dev" -e "aws_profile=sid-KS"
ansible-playbook playbooks/main.yml --tags rosa-cli -e "target_environment=dev" -e "aws_profile=sid-KS"
ansible-playbook playbooks/main.yml --tags cluster -e "target_environment=dev" -e "aws_profile=sid-KS"
ansible-playbook playbooks/main.yml --tags cf-db -e "target_environment=dev" -e "aws_profile=sid-KS"
ansible-playbook playbooks/main.yml --tags cf-deployment -e "target_environment=dev" -e "aws_profile=sid-KS"
ansible-playbook playbooks/main.yml --tags monitoring -e "target_environment=dev" -e "aws_profile=sid-KS"
ansible-playbook playbooks/main.yml --tags routes -e "target_environment=dev" -e "aws_profile=sid-KS"

# CF-DB role individual tasks (with dynamic AWS profile)
ansible-playbook playbooks/main.yml --tags networking -e "target_environment=dev" -e "aws_profile=sid-KS"
ansible-playbook playbooks/main.yml --tags security -e "target_environment=dev" -e "aws_profile=sid-KS"
ansible-playbook playbooks/main.yml --tags aurora -e "target_environment=dev" -e "aws_profile=sid-KS"

# Validation and testing
ansible-playbook playbooks/main.yml --check --diff -e "target_environment=dev" -e "aws_profile=sid-KS"
ansible-playbook playbooks/main.yml --syntax-check
ansible-playbook playbooks/main.yml -vvv -e "target_environment=dev"
```

### Helm Chart Management
```bash
# Install/upgrade microservices using Helm
helm install cf-microservices helm-charts/cf-microservices/ -n cf-dev --values environments/dev/deployment-values.yaml
helm upgrade cf-microservices helm-charts/cf-microservices/ -n cf-dev --values environments/dev/deployment-values.yaml
helm uninstall cf-microservices -n cf-dev

# Template generation and testing
helm template cf-microservices helm-charts/cf-microservices/ --values environments/dev/deployment-values.yaml
helm lint helm-charts/cf-microservices/
```

### Environment Management
```bash
# Source environment variables after setup
source environments/dev/export_env.sh
source environments/test/export_env.sh
source environments/prod/export_env.sh

# Validate environment configuration
ansible-playbook playbooks/main.yml --tags validation -e "target_environment=dev"
```

## Architecture Overview

### High-Level Infrastructure Pattern
This repository implements a complete ROSA (Red Hat OpenShift Service on AWS) infrastructure automation using Ansible, following a multi-tier architecture:

**Tier 1: Foundation Infrastructure**
- AWS CLI and ROSA CLI setup (`aws-setup`, `rosa-cli` roles) 
- ROSA cluster provisioning (`cluster` role)
- Network and database infrastructure (`cf-db` role)

**Tier 2: Platform Services**
- Monitoring stack with Prometheus/Grafana (`monitoring` role)
- Route management for external access (`routes` role)

**Tier 3: Application Layer**
- Microservices deployment using Helm charts (`cf-deployment` role)
- ECR integration with OpenShift service accounts
- Spring Boot microservices ecosystem (API Gateway, Config Server, etc.)

### Microservices Architecture
The application follows a distributed microservices pattern with:
- **Service Discovery**: Naming Server (Eureka) on port 8761
- **API Gateway**: Central routing and authentication on port 8765
- **Configuration Management**: Spring Cloud Config on port 8888
- **Monitoring**: Spring Boot Admin on port 8082
- **Business Services**: 
  - Bench Profile Service (8081)
  - Excel Service (8083) 
  - Daily Submissions (8084)
  - Placements (8085)
  - Interviews (8086)
- **Frontend**: React application on port 3000

### Environment Configuration Pattern
Each environment (dev/test/prod) maintains:
- Ansible variable files in `environments/{env}/{env}.yml`
- Helm values in `environments/{env}/deployment-values.yaml`
- Database configuration in `environments/{env}/cf-db.yml`
- Cluster configuration in `environments/{env}/cluster-config.yml`

### Role Dependencies and Execution Order
The `playbooks/main.yml` orchestrates roles in this sequence:
1. `aws-setup` - AWS CLI and environment setup
2. `rosa-cli` - ROSA CLI installation and authentication
3. `validation` - Prerequisites and configuration validation
4. `cluster` - ROSA cluster creation and configuration
5. `monitoring` - Prometheus/Grafana deployment
6. `routes` - OpenShift route management
7. `cf-db` - Aurora PostgreSQL cluster with cross-VPC access
8. `cf-deployment` - Microservices deployment via Helm

### Key Architecture Decisions
- **Network Isolation**: Aurora database uses separate VPC (172.31.0.0/16) to avoid ROSA CIDR conflicts
- **Cross-VPC Access**: VPC peering enables ROSA-to-Aurora connectivity
- **Service Mesh**: Uses OpenShift Routes with TLS termination
- **Container Registry**: ECR integration with OpenShift service accounts and RBAC
- **Scaling Strategy**: Horizontal Pod Autoscaling with resource-based metrics
- **Security**: Private Aurora clusters with security group restrictions

### Helm Chart Structure
The `helm-charts/cf-microservices/` umbrella chart follows a sub-chart pattern:
- Parent chart manages global configurations and service enablement flags
- Individual service charts in `charts/` directory handle deployment-specific settings
- Values inheritance from global to service-specific configurations
- Consistent templating for deployments, services, and routes across all services

### Environment-Specific Behavior
- **Dev**: Minimal resource allocation, relaxed validation, single AZ deployment
- **Test**: Production-mirrored setup with full validation for integration testing  
- **Prod**: Multi-AZ, strict security, comprehensive monitoring, backup strategies
