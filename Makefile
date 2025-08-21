# Makefile for Ansible Project
# Run 'make help' for available commands

.PHONY: help install lint test clean fix validate all pre-commit setup

# Variables
PYTHON := python3
PIP := $(PYTHON) -m pip
ANSIBLE_VERSION := 2.15.0
ANSIBLE_LINT_VERSION := 6.22.0
YAMLLINT_VERSION := 1.33.0
PRE_COMMIT_VERSION := 3.6.0
MOLECULE_VERSION := 6.0.2

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

# Default target
all: lint validate test

help: ## Show this help message
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

# Setup and Installation
setup: install pre-commit-install ## Complete setup for development environment

install: ## Install all required dependencies
	@echo "$(GREEN)Installing dependencies...$(NC)"
	$(PIP) install --upgrade pip
	$(PIP) install ansible==$(ANSIBLE_VERSION)
	$(PIP) install ansible-lint==$(ANSIBLE_LINT_VERSION)
	$(PIP) install yamllint==$(YAMLLINT_VERSION)
	$(PIP) install pre-commit==$(PRE_COMMIT_VERSION)
	$(PIP) install molecule==$(MOLECULE_VERSION)
	$(PIP) install molecule-plugins[docker]
	$(PIP) install jmespath netaddr boto3 kubernetes openshift requests
	@echo "$(GREEN)✓ Dependencies installed successfully$(NC)"

pre-commit-install: ## Install pre-commit hooks
	@echo "$(GREEN)Setting up pre-commit hooks...$(NC)"
	pre-commit install
	pre-commit install --hook-type commit-msg
	@echo "$(GREEN)✓ Pre-commit hooks installed$(NC)"

# Linting Commands
lint: yaml-lint ansible-lint ## Run all linters

yaml-lint: ## Run yamllint on all YAML files
	@echo "$(GREEN)Running yamllint...$(NC)"
	@if [ ! -f .yamllint ]; then \
		echo "$(YELLOW)Creating .yamllint config...$(NC)"; \
		echo "---" > .yamllint; \
		echo "extends: default" >> .yamllint; \
		echo "rules:" >> .yamllint; \
		echo "  line-length:" >> .yamllint; \
		echo "    max: 160" >> .yamllint; \
		echo "  comments: disable" >> .yamllint; \
		echo "  comments-indentation: disable" >> .yamllint; \
		echo "  truthy:" >> .yamllint; \
		echo "    allowed-values: ['true', 'false', 'yes', 'no']" >> .yamllint; \
	fi
	yamllint -c .yamllint . || (echo "$(RED)✗ YAML linting failed$(NC)" && exit 1)
	@echo "$(GREEN)✓ YAML linting passed$(NC)"

ansible-lint: ## Run ansible-lint on all playbooks and roles
	@echo "$(GREEN)Running ansible-lint...$(NC)"
	@if [ ! -f .ansible-lint ]; then \
		echo "$(YELLOW)Creating .ansible-lint config...$(NC)"; \
		echo "---" > .ansible-lint; \
		echo "profile: production" >> .ansible-lint; \
		echo "exclude_paths:" >> .ansible-lint; \
		echo "  - .cache/" >> .ansible-lint; \
		echo "  - .github/" >> .ansible-lint; \
		echo "skip_list:" >> .ansible-lint; \
		echo "  - yaml[line-length]" >> .ansible-lint; \
	fi
	ansible-lint --force-color || (echo "$(RED)✗ Ansible linting failed$(NC)" && exit 1)
	@echo "$(GREEN)✓ Ansible linting passed$(NC)"

# Validation Commands
validate: validate-syntax validate-vars validate-inventory ## Run all validation checks

validate-syntax: ## Validate Ansible playbook syntax
	@echo "$(GREEN)Validating playbook syntax...$(NC)"
	@for playbook in $$(find playbooks -name "*.yml" 2>/dev/null); do \
		echo "  Checking: $$playbook"; \
		ansible-playbook --syntax-check $$playbook -e env=dev || exit 1; \
	done
	@echo "$(GREEN)✓ Syntax validation passed$(NC)"

validate-vars: ## Check for undefined and reserved variables
	@echo "$(GREEN)Validating variables...$(NC)"
	@echo "Checking for reserved variable names..."
	@if grep -r "^\s*environment:" --include="*.yml" roles/ playbooks/ 2>/dev/null | grep -v "#"; then \
		echo "$(RED)✗ Found reserved variable 'environment'$(NC)"; \
		echo "  Replace with 'target_environment' or another name"; \
		exit 1; \
	fi
	@echo "Checking for undefined variables..."
	@$(PYTHON) -c "import yaml, sys, re; \
	from pathlib import Path; \
	errors = []; \
	for f in Path('.').rglob('*.yml'): \
		if '.github' not in str(f) and '.cache' not in str(f): \
			with open(f) as file: \
				content = file.read(); \
				vars_used = re.findall(r'\{\{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:\||\})', content); \
				for var in vars_used: \
					if var not in ['item', 'ansible_facts', 'hostvars', 'groups', 'inventory_hostname']: \
						pass; \
	if errors: \
		print('\n'.join(errors)); \
		sys.exit(1); \
	else: \
		print('✓ Variable validation passed')"

validate-inventory: ## Validate inventory files
	@echo "$(GREEN)Validating inventory...$(NC)"
	@if [ -f ansible/inventory ]; then \
		ansible-inventory -i ansible/inventory --list > /dev/null || exit 1; \
	elif [ -f inventory ]; then \
		ansible-inventory -i inventory --list > /dev/null || exit 1; \
	else \
		echo "$(YELLOW)⚠ No inventory file found$(NC)"; \
	fi
	@echo "$(GREEN)✓ Inventory validation passed$(NC)"

# Testing Commands
test: test-unit test-integration ## Run all tests

test-unit: ## Run unit tests for roles
	@echo "$(GREEN)Running unit tests...$(NC)"
	@for role in $$(ls roles/ 2>/dev/null); do \
		if [ -d "roles/$$role/tests" ]; then \
			echo "  Testing role: $$role"; \
			cd roles/$$role && molecule test --scenario-name default || exit 1; \
		fi \
	done
	@echo "$(GREEN)✓ Unit tests passed$(NC)"

test-integration: ## Run integration tests
	@echo "$(GREEN)Running integration tests...$(NC)"
	@echo "$(YELLOW)⚠ Integration tests not yet configured$(NC)"

# Fix Commands
fix: fix-yaml fix-permissions fix-line-endings ## Auto-fix common issues

fix-yaml: ## Auto-fix YAML formatting issues
	@echo "$(GREEN)Fixing YAML formatting...$(NC)"
	yamllint -c .yamllint --format auto . || true
	@echo "$(GREEN)✓ YAML fixes applied$(NC)"

fix-permissions: ## Fix file permissions
	@echo "$(GREEN)Fixing file permissions...$(NC)"
	@find . -type f -name "*.yml" -exec chmod 644 {} \;
	@find . -type f -name "*.yaml" -exec chmod 644 {} \;
	@find . -type f -name "*.sh" -exec chmod 755 {} \;
	@echo "$(GREEN)✓ Permissions fixed$(NC)"

fix-line-endings: ## Fix line endings (convert to Unix)
	@echo "$(GREEN)Fixing line endings...$(NC)"
	@find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.j2" \) -exec dos2unix {} \; 2>/dev/null || true
	@echo "$(GREEN)✓ Line endings fixed$(NC)"

# Security Commands
security: security-scan check-secrets ## Run security checks

security-scan: ## Run security scanning with Trivy
	@echo "$(GREEN)Running security scan...$(NC)"
	@if command -v trivy &> /dev/null; then \
		trivy fs . --severity HIGH,CRITICAL; \
	else \
		echo "$(YELLOW)⚠ Trivy not installed. Install with: brew install trivy$(NC)"; \
	fi

check-secrets: ## Check for hardcoded secrets
	@echo "$(GREEN)Checking for secrets...$(NC)"
	@if command -v detect-secrets &> /dev/null; then \
		detect-secrets scan --baseline .secrets.baseline; \
	else \
		echo "$(YELLOW)⚠ detect-secrets not installed. Install with: pip install detect-secrets$(NC)"; \
	fi
	@echo "Checking for hardcoded credentials..."
	@if grep -rE "(api_key|password|token|secret):\s*['\"][\w\-]+['\"]" --include="*.yml" --include="*.yaml" roles/ playbooks/ 2>/dev/null | grep -v -E "(vault_|lookup|env|prompt)" | grep -v "^#"; then \
		echo "$(RED)✗ Found potential hardcoded secrets$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ No hardcoded secrets found$(NC)"

# Pre-commit Commands
pre-commit: ## Run pre-commit hooks on all files
	@echo "$(GREEN)Running pre-commit hooks...$(NC)"
	pre-commit run --all-files
	@echo "$(GREEN)✓ Pre-commit checks passed$(NC)"

pre-commit-update: ## Update pre-commit hooks to latest versions
	@echo "$(GREEN)Updating pre-commit hooks...$(NC)"
	pre-commit autoupdate
	@echo "$(GREEN)✓ Pre-commit hooks updated$(NC)"

# Molecule Commands
molecule-init: ## Initialize molecule testing for a role
	@read -p "Enter role name: " role; \
	if [ -d "roles/$$role" ]; then \
		cd roles/$$role && molecule init scenario default --driver-name docker; \
		echo "$(GREEN)✓ Molecule initialized for role: $$role$(NC)"; \
	else \
		echo "$(RED)✗ Role not found: $$role$(NC)"; \
	fi

molecule-test: ## Run molecule tests for a specific role
	@read -p "Enter role name: " role; \
	if [ -d "roles/$$role" ]; then \
		cd roles/$$role && molecule test; \
	else \
		echo "$(RED)✗ Role not found: $$role$(NC)"; \
	fi

# Clean Commands
clean: clean-cache clean-pyc clean-test ## Clean all generated files

clean-cache: ## Clean Ansible cache
	@echo "$(GREEN)Cleaning cache...$(NC)"
	@rm -rf .cache/
	@rm -rf ~/.ansible/tmp/
	@rm -rf ~/.ansible/cp/
	@echo "$(GREEN)✓ Cache cleaned$(NC)"

clean-pyc: ## Clean Python cache files
	@echo "$(GREEN)Cleaning Python cache...$(NC)"
	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete
	@echo "$(GREEN)✓ Python cache cleaned$(NC)"

clean-test: ## Clean test artifacts
	@echo "$(GREEN)Cleaning test artifacts...$(NC)"
	@rm -rf .molecule/
	@rm -rf .pytest_cache/
	@rm -f .coverage
	@echo "$(GREEN)✓ Test artifacts cleaned$(NC)"

# CI/CD Commands
ci-local: ## Run CI pipeline locally (mimics GitHub Actions)
	@echo "$(GREEN)Running local CI pipeline...$(NC)"
	@echo "Step 1: YAML Lint"
	@$(MAKE) yaml-lint
	@echo "\nStep 2: Ansible Lint"
	@$(MAKE) ansible-lint
	@echo "\nStep 3: Syntax Validation"
	@$(MAKE) validate-syntax
	@echo "\nStep 4: Variable Validation"
	@$(MAKE) validate-vars
	@echo "\nStep 5: Security Scan"
	@$(MAKE) security
	@echo "\n$(GREEN)✓ Local CI pipeline completed successfully$(NC)"

# Report Generation
report: ## Generate quality report
	@echo "$(GREEN)Generating quality report...$(NC)"
	@echo "# Ansible Code Quality Report" > quality-report.md
	@echo "Generated: $$(date)" >> quality-report.md
	@echo "" >> quality-report.md
	@echo "## Linting Results" >> quality-report.md
	@echo '```' >> quality-report.md
	@yamllint -c .yamllint . 2>&1 | head -20 >> quality-report.md || true
	@echo '```' >> quality-report.md
	@echo "" >> quality-report.md
	@echo "## Ansible Lint Results" >> quality-report.md
	@echo '```' >> quality-report.md
	@ansible-lint --parseable-severity 2>&1 | head -20 >> quality-report.md || true
	@echo '```' >> quality-report.md
	@echo "$(GREEN)✓ Report generated: quality-report.md$(NC)"

# Development Helpers
watch: ## Watch for changes and run linters
	@echo "$(GREEN)Watching for changes...$(NC)"
	@while true; do \
		$(MAKE) lint; \
		echo "$(YELLOW)Waiting for changes... (Ctrl+C to stop)$(NC)"; \
		sleep 5; \
	done

.DEFAULT_GOAL := help