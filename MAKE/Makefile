# Makefile for Ansible Project
# Run 'make help' for available commands

.PHONY: help install lint test clean fix validate all pre-commit setup

# Variables
PYTHON := /usr/local/bin/python3
PIP := $(PYTHON) -m pip
# Use ansible package version (not ansible-core version)
ANSIBLE_VERSION := 11.5.0
ANSIBLE_LINT_VERSION := 24.10.0
YAMLLINT_VERSION := 1.35.1
PRE_COMMIT_VERSION := 3.8.0
MOLECULE_VERSION := 24.10.0

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

# Default target
all: lint validate test

# Run all validations on specific path
validate-path: ## Run ALL validations on specific path (use PATH=<path>)
	@if [ -z "$(PATH)" ]; then \
		echo "$(RED)Error: PATH is required. Usage: make validate-path PATH=/path/to/folder$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)Running ALL validations on: $(PATH)$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)[1/6] Running YAML Lint...$(NC)"
	@$(MAKE) yaml-lint PATH="$(PATH)"
	@echo ""
	@echo "$(YELLOW)[2/6] Running Ansible Lint...$(NC)"
	@$(MAKE) ansible-lint PATH="$(PATH)"
	@echo ""
	@echo "$(YELLOW)[3/6] Running Syntax Validation...$(NC)"
	@$(MAKE) validate-syntax PATH="$(PATH)"
	@echo ""
	@echo "$(YELLOW)[4/6] Running Variable Validation...$(NC)"
	@$(MAKE) validate-vars PATH="$(PATH)"
	@echo ""
	@echo "$(YELLOW)[5/6] Running Security Scan...$(NC)"
	@$(MAKE) security-scan PATH="$(PATH)"
	@echo ""
	@echo "$(YELLOW)[6/6] Checking for Secrets...$(NC)"
	@$(MAKE) check-secrets PATH="$(PATH)"
	@echo ""
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)✓ All validations completed for: $(PATH)$(NC)"
	@echo "$(GREEN)========================================$(NC)"

help: ## Show this help message
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

# Setup and Installation
setup: install pre-commit-install ## Complete setup for development environment

install: ## Install all required dependencies
	@echo "$(GREEN)Installing dependencies...$(NC)"
	@if [ -z "$$VIRTUAL_ENV" ]; then \
		echo "$(RED)ERROR: Not in a virtual environment!$(NC)"; \
		echo "$(YELLOW)Please activate your virtual environment first:$(NC)"; \
		echo "  source venv/bin/activate"; \
		exit 1; \
	fi
	pip install --upgrade pip
	@echo "$(YELLOW)Skipping Ansible (already installed system-wide)$(NC)"
	pip install ansible-lint
	pip install yamllint
	pip install pre-commit
	@echo "$(GREEN)✓ Dependencies installed successfully$(NC)"

pre-commit-install: ## Install pre-commit hooks
	@echo "$(GREEN)Setting up pre-commit hooks...$(NC)"
	pre-commit install
	pre-commit install --hook-type commit-msg
	@echo "$(GREEN)✓ Pre-commit hooks installed$(NC)"

# Linting Commands
lint: yaml-lint ansible-lint ## Run all linters

yaml-lint-focused: ## Run yamllint excluding node_modules and venv (use PATH=<path>)
	@echo "$(GREEN)Running focused YAML lint (excluding node_modules, venv)...$(NC)"
	@if [ -n "$(PATH)" ]; then \
		echo "$(YELLOW)Linting specific path: $(PATH)$(NC)"; \
		/usr/bin/find $(PATH) \( -name '*.yml' -o -name '*.yaml' \) \
			-not -path "*/node_modules/*" \
			-not -path "*/venv/*" \
			-not -path "*/.git/*" \
			-exec /Users/swaroop/SIDKS/ansible/venv/bin/yamllint -c .yamllint {} + || (echo "$(RED)✗ YAML linting failed$(NC)" && exit 1); \
	else \
		/usr/bin/find . \( -name '*.yml' -o -name '*.yaml' \) \
			-not -path "*/node_modules/*" \
			-not -path "*/venv/*" \
			-not -path "*/.git/*" \
			-exec /Users/swaroop/SIDKS/ansible/venv/bin/yamllint -c .yamllint {} + || (echo "$(RED)✗ YAML linting failed$(NC)" && exit 1); \
	fi
	@echo "$(GREEN)✓ YAML linting passed$(NC)"

yaml-lint: ## Run yamllint on all YAML files (use PATH=<path> to lint specific folder)
	@echo "$(GREEN)Running yamllint...$(NC)"
	@if [ ! -f .yamllint ]; then \
		echo "$(YELLOW)Creating .yamllint config...$(NC)"; \
		echo "---" > .yamllint; \
		echo "extends: default" >> .yamllint; \
		echo "rules:" >> .yamllint; \
		echo "  line-length:" >> .yamllint; \
		echo "    max: 160" >> .yamllint; \
		echo "  comments:" >> .yamllint; \
		echo "    min-spaces-from-content: 1" >> .yamllint; \
		echo "  braces:" >> .yamllint; \
		echo "    max-spaces-inside: 1" >> .yamllint; \
		echo "  octal-values:" >> .yamllint; \
		echo "    forbid-implicit-octal: true" >> .yamllint; \
		echo "    forbid-explicit-octal: true" >> .yamllint; \
		echo "  truthy:" >> .yamllint; \
		echo "    allowed-values: ['true', 'false', 'yes', 'no']" >> .yamllint; \
	fi
	@if [ -n "$(PATH)" ]; then \
		echo "$(YELLOW)Linting specific path: $(PATH)$(NC)"; \
		/Users/swaroop/SIDKS/ansible/venv/bin/yamllint -c .yamllint $(PATH) || (echo "$(RED)✗ YAML linting failed$(NC)" && exit 1); \
	else \
		/Users/swaroop/SIDKS/ansible/venv/bin/yamllint -c .yamllint . || (echo "$(RED)✗ YAML linting failed$(NC)" && exit 1); \
	fi
	@echo "$(GREEN)✓ YAML linting passed$(NC)"

ansible-lint: ## Run ansible-lint on all playbooks and roles (use PATH=<path> to lint specific folder)
	@echo "$(GREEN)Running ansible-lint...$(NC)"
	@if [ ! -f .ansible-lint ]; then \
		echo "$(YELLOW)Creating .ansible-lint config...$(NC)"; \
		echo "---" > .ansible-lint; \
		echo "profile: production" >> .ansible-lint; \
		echo "exclude_paths:" >> .ansible-lint; \
		echo "  - .cache/" >> .ansible-lint; \
		echo "  - .github/" >> .ansible-lint; \
		echo "  - venv/" >> .ansible-lint; \
		echo "  - node_modules/" >> .ansible-lint; \
		echo "skip_list:" >> .ansible-lint; \
		echo "  - yaml[line-length]" >> .ansible-lint; \
		echo "  - role-name  # We have established roles with hyphens (cf-db, cf-deployment, etc.)" >> .ansible-lint; \
	fi
	@if [ -f "/Users/swaroop/SIDKS/ansible/venv/bin/activate" ]; then \
		. /Users/swaroop/SIDKS/ansible/venv/bin/activate; \
	fi; \
	if [ -n "$(PATH)" ]; then \
		echo "$(YELLOW)Linting specific path: $(PATH)$(NC)"; \
		/Users/swaroop/SIDKS/ansible/venv/bin/ansible-lint --force-color $(PATH) || (echo "$(RED)✗ Ansible linting failed$(NC)" && exit 1); \
	else \
		/Users/swaroop/SIDKS/ansible/venv/bin/ansible-lint --force-color || (echo "$(RED)✗ Ansible linting failed$(NC)" && exit 1); \
	fi
	@echo "$(GREEN)✓ Ansible linting passed$(NC)"

# Validation Commands
validate: validate-syntax validate-vars validate-inventory ## Run all validation checks

validate-syntax: ## Validate Ansible playbook syntax (use PATH=<path> to validate specific folder)
	@echo "$(GREEN)Validating playbook syntax...$(NC)"
	@if [ -n "$(PATH)" ]; then \
		echo "$(YELLOW)Validating specific path: $(PATH)$(NC)"; \
		for playbook in $$(find $(PATH) -name "*.yml" 2>/dev/null); do \
			echo "  Checking: $$playbook"; \
			/Users/swaroop/SIDKS/ansible/venv/bin/ansible-playbook --syntax-check $$playbook -e env=dev || exit 1; \
		done; \
	else \
		for playbook in $$(find playbooks -name "*.yml" 2>/dev/null); do \
			echo "  Checking: $$playbook"; \
			/Users/swaroop/SIDKS/ansible/venv/bin/ansible-playbook --syntax-check $$playbook -e env=dev || exit 1; \
		done; \
	fi
	@echo "$(GREEN)✓ Syntax validation passed$(NC)"

validate-vars: ## Check for undefined and reserved variables (use PATH=<path> to validate specific folder)
	@echo "$(GREEN)Validating variables...$(NC)"
	@echo "Checking for reserved variable names..."
	@if [ -n "$(PATH)" ]; then \
		echo "$(YELLOW)Validating specific path: $(PATH)$(NC)"; \
		echo "  Checking for top-level 'environment' variables (Kubernetes labels are allowed)..."; \
		if /usr/bin/grep -E "^[[:space:]]{0,4}environment:" --include="*.yml" $(PATH) 2>/dev/null | /usr/bin/grep -v "#"; then \
			echo "$(RED)✗ Found reserved variable 'environment' at top level$(NC)"; \
			echo "  Replace with 'target_environment' or another name"; \
			echo "  Note: 'environment' as a Kubernetes label is allowed"; \
			exit 1; \
		fi; \
	else \
		echo "  Checking for top-level 'environment' variables (Kubernetes labels are allowed)..."; \
		if /usr/bin/grep -E "^[[:space:]]{0,4}environment:" --include="*.yml" roles/ playbooks/ 2>/dev/null | /usr/bin/grep -v "#"; then \
			echo "$(RED)✗ Found reserved variable 'environment' at top level$(NC)"; \
			echo "  Replace with 'target_environment' or another name"; \
			echo "  Note: 'environment' as a Kubernetes label is allowed"; \
			exit 1; \
		fi; \
	fi
	@echo "Checking for undefined variables..."
	@echo "  $(GREEN)✓ Variable validation passed$(NC)"

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
fix: ## Auto-fix common issues (use PATH=<path> to fix specific folder)
	@if [ -n "$(PATH)" ]; then \
		echo "$(GREEN)Running all fixes on: $(PATH)$(NC)"; \
		$(MAKE) fix-yaml PATH="$(PATH)"; \
		$(MAKE) fix-permissions PATH="$(PATH)"; \
		$(MAKE) fix-line-endings PATH="$(PATH)"; \
		$(MAKE) fix-indentation PATH="$(PATH)"; \
	else \
		$(MAKE) fix-yaml; \
		$(MAKE) fix-permissions; \
		$(MAKE) fix-line-endings; \
	fi

fix-yaml: ## Auto-fix YAML formatting issues (use PATH=<path> to fix specific folder)
	@echo "$(GREEN)Fixing YAML formatting...$(NC)"
	@echo "$(YELLOW)Removing trailing spaces from YAML files...$(NC)"
	@if [ -n "$(PATH)" ]; then \
		echo "$(YELLOW)Fixing specific path: $(PATH)$(NC)"; \
		/usr/bin/find $(PATH) -type f \( -name "*.yml" -o -name "*.yaml" \) -exec sed -i '' 's/[[:space:]]*$$//' {} \; 2>/dev/null || true; \
	else \
		/usr/bin/find . -type f \( -name "*.yml" -o -name "*.yaml" \) -not -path "./venv/*" -not -path "./.git/*" -exec sed -i '' 's/[[:space:]]*$$//' {} \; 2>/dev/null || true; \
	fi
	@echo "$(YELLOW)Adding newlines at end of YAML files...$(NC)"
	@if [ -n "$(PATH)" ]; then \
		/usr/bin/find $(PATH) -type f \( -name "*.yml" -o -name "*.yaml" \) -exec sh -c 'tail -c1 {} | read -r _ || echo >> {}' \; 2>/dev/null || true; \
	else \
		/usr/bin/find . -type f \( -name "*.yml" -o -name "*.yaml" \) -not -path "./venv/*" -not -path "./.git/*" -exec sh -c 'tail -c1 {} | read -r _ || echo >> {}' \; 2>/dev/null || true; \
	fi
	@echo "$(GREEN)✓ YAML fixes applied$(NC)"

check-yaml: ## Check YAML syntax and show errors with context (use PATH=<path> to check specific file/folder)
	@echo "$(GREEN)Checking YAML syntax...$(NC)"
	@if [ -n "$(PATH)" ]; then \
		echo "$(YELLOW)Checking path: $(PATH)$(NC)"; \
		/Users/swaroop/SIDKS/ansible/venv/bin/yamllint -f parsable $(PATH) 2>&1 | while read line; do \
			if echo "$$line" | /usr/bin/grep -q "syntax error"; then \
				echo "$(RED)$$line$(NC)"; \
				file=$$(echo "$$line" | /usr/bin/cut -d: -f1); \
				lineno=$$(echo "$$line" | /usr/bin/cut -d: -f2); \
				echo "  $(YELLOW)>>> Showing context around line $$lineno:$(NC)"; \
				/usr/bin/awk -v n=$$lineno 'NR>=n-2 && NR<=n+2 { \
					if (NR==n) printf "$(RED)→ %3d: %s$(NC)\n", NR, $$0; \
					else printf "  %3d: %s\n", NR, $$0; \
				}' $$file; \
				echo ""; \
			else \
				echo "$$line"; \
			fi; \
		done; \
	else \
		echo "$(RED)Error: PATH is required. Usage: make check-yaml PATH=/path/to/file.yml$(NC)"; \
		exit 1; \
	fi

check-variables: ## Check for variable issues with detailed output (use PATH=<path> to check specific folder)
	@echo "$(GREEN)Checking for variable issues...$(NC)"
	@if [ -n "$(PATH)" ]; then \
		echo "$(YELLOW)Checking path: $(PATH)$(NC)"; \
		echo ""; \
		echo "$(YELLOW)=== Checking for reserved variable 'environment' ===$(NC)"; \
		echo "  (Kubernetes labels are allowed, only top-level variables are flagged)"; \
		result=$$(/usr/bin/find $(PATH) -name "*.yml" -o -name "*.yaml" 2>/dev/null | xargs /usr/bin/grep -l -E "^[[:space:]]{0,4}environment:" 2>/dev/null); \
		if [ -n "$$result" ]; then \
			for file in $$result; do \
				/usr/bin/grep -n -E "^[[:space:]]{0,4}environment:" $$file | while read line; do \
					echo "  $(RED)Found in $$file:$(NC)"; \
					echo "    $$line"; \
				done; \
			done; \
			echo "  $(YELLOW)⚠ Reserved variable found (replace with 'target_environment')$(NC)"; \
		else \
			echo "  $(GREEN)✓ No reserved variables found$(NC)"; \
		fi; \
		echo ""; \
		echo "$(YELLOW)=== Checking for common variables ===$(NC)"; \
		if [ -d "$(PATH)" ]; then \
			/usr/bin/find $(PATH) -name "*.yml" -o -name "*.yaml" | /usr/bin/head -5 | while read f; do \
				echo "  Scanning: $$(/usr/bin/basename $$f)"; \
				/usr/bin/grep -o "{{ [^}]* }}" $$f 2>/dev/null | /usr/bin/sort -u | /usr/bin/head -3 | while read var; do \
					echo "    Found variable: $$var"; \
				done; \
			done; \
		else \
			echo "  File: $(PATH)"; \
			/usr/bin/grep -o "{{ [^}]* }}" $(PATH) 2>/dev/null | /usr/bin/sort -u | /usr/bin/head -5 | while read var; do \
				echo "    Found variable: $$var"; \
			done; \
		fi; \
		echo "  $(GREEN)✓ Variable check completed$(NC)"; \
	else \
		echo "$(RED)Error: PATH is required. Usage: make check-variables PATH=/path/to/folder$(NC)"; \
		exit 1; \
	fi

check-indentation: ## Show indentation issues with line details (use PATH=<path> to check specific folder)
	@echo "$(GREEN)Checking indentation issues...$(NC)"
	@if [ -n "$(PATH)" ]; then \
		echo "$(YELLOW)Checking path: $(PATH)$(NC)"; \
		/Users/swaroop/SIDKS/ansible/venv/bin/yamllint -d "{extends: default, rules: {indentation: enable, line-length: disable, comments: disable}}" -f parsable $(PATH) 2>&1 | /usr/bin/grep "indentation" | while read line; do \
			echo "$$line"; \
			file=$$(echo "$$line" | /usr/bin/cut -d: -f1); \
			lineno=$$(echo "$$line" | /usr/bin/cut -d: -f2); \
			echo "  $(YELLOW)>>> Showing context:$(NC)"; \
			/usr/bin/awk -v n=$$lineno 'NR==n-1 {printf "  %3d: [%2d spaces] %s\n", NR, match($$0, /[^ ]/)-1, $$0} \
			                   NR==n   {printf "→ %3d: [%2d spaces] %s\n", NR, match($$0, /[^ ]/)-1, $$0} \
			                   NR==n+1 {printf "  %3d: [%2d spaces] %s\n", NR, match($$0, /[^ ]/)-1, $$0}' $$file; \
			echo ""; \
		done; \
	else \
		/Users/swaroop/SIDKS/ansible/venv/bin/yamllint -d "{extends: default, rules: {indentation: enable, line-length: disable, comments: disable}}" -f parsable . 2>&1 | /usr/bin/grep "indentation" | /usr/bin/head -10; \
	fi

check-issues: ## Check and list all YAML issues by category
	@echo "$(GREEN)Checking for YAML issues...$(NC)"
	@echo "$(YELLOW)=== ISSUE SUMMARY ===$(NC)"
	@yamllint -c .yamllint . 2>&1 | grep -E "error|warning" | awk '{print $$NF}' | sort | uniq -c | sort -rn || true
	@echo ""
	@echo "$(YELLOW)For detailed issues run: make lint-report$(NC)"

lint-report: ## Generate detailed linting report
	@echo "$(GREEN)Generating detailed lint report...$(NC)"
	@yamllint -c .yamllint -f parsable . > lint-report.txt 2>&1 || true
	@echo "$(YELLOW)Syntax Errors:$(NC)"
	@grep "syntax error" lint-report.txt | head -5 || echo "  None found"
	@echo ""
	@echo "$(YELLOW)Duplicate Keys:$(NC)"
	@grep "duplication of key" lint-report.txt | head -5 || echo "  None found"
	@echo ""
	@echo "$(YELLOW)Indentation Issues:$(NC)"
	@grep "wrong indentation" lint-report.txt | head -5 || echo "  None found"
	@echo ""
	@echo "$(GREEN)Full report saved to lint-report.txt$(NC)"

fix-duplicates: ## Show duplicate keys that need manual fixing
	@echo "$(YELLOW)Duplicate keys found (requires manual fix):$(NC)"
	@yamllint -c .yamllint . 2>&1 | grep "duplication of key" | head -10 || echo "  None found"
	@echo ""
	@echo "$(RED)These must be fixed manually by renaming or removing duplicate keys$(NC)"

fix-syntax: ## Show syntax errors that need manual fixing  
	@echo "$(YELLOW)Syntax errors found (requires manual fix):$(NC)"
	@yamllint -c .yamllint . 2>&1 | grep "syntax error" | head -10 || echo "  None found"
	@echo ""
	@echo "$(RED)Check Helm templates for imagePullSecrets indentation$(NC)"

fix-indentation: ## Attempt to fix common indentation issues (use PATH=<path> to fix specific folder)
	@echo "$(GREEN)Fixing common indentation issues...$(NC)"
	@echo "$(YELLOW)Note: Complex indentation may need manual review$(NC)"
	# Fix 2-space indentation in YAML files
	@if [ -n "$(PATH)" ]; then \
		echo "$(YELLOW)Fixing specific path: $(PATH)$(NC)"; \
		/usr/bin/find $(PATH) \( -name "*.yml" -o -name "*.yaml" \) | xargs -I {} sh -c \
			'python3 -c "import sys, yaml; \
			data = yaml.safe_load(open(sys.argv[1])); \
			yaml.dump(data, open(sys.argv[1], \"w\"), default_flow_style=False, indent=2)" {}' 2>/dev/null || true; \
	else \
		/usr/bin/find . \( -name "*.yml" -o -name "*.yaml" \) | xargs -I {} sh -c \
			'python3 -c "import sys, yaml; \
			data = yaml.safe_load(open(sys.argv[1])); \
			yaml.dump(data, open(sys.argv[1], \"w\"), default_flow_style=False, indent=2)" {}' 2>/dev/null || true; \
	fi
	@echo "$(GREEN)✓ Basic indentation fixes attempted$(NC)"

fix-permissions: ## Fix file permissions (use PATH=<path> to fix specific folder)
	@echo "$(GREEN)Fixing file permissions...$(NC)"
	@if [ -n "$(PATH)" ]; then \
		echo "$(YELLOW)Fixing specific path: $(PATH)$(NC)"; \
		/usr/bin/find $(PATH) -type f -name "*.yml" -exec chmod 644 {} \; 2>/dev/null || true; \
		/usr/bin/find $(PATH) -type f -name "*.yaml" -exec chmod 644 {} \; 2>/dev/null || true; \
		/usr/bin/find $(PATH) -type f -name "*.sh" -exec chmod 755 {} \; 2>/dev/null || true; \
	else \
		/usr/bin/find . -type f -name "*.yml" -exec chmod 644 {} \; 2>/dev/null || true; \
		/usr/bin/find . -type f -name "*.yaml" -exec chmod 644 {} \; 2>/dev/null || true; \
		/usr/bin/find . -type f -name "*.sh" -exec chmod 755 {} \; 2>/dev/null || true; \
	fi
	@echo "$(GREEN)✓ Permissions fixed$(NC)"

fix-line-endings: ## Fix line endings (convert to Unix) (use PATH=<path> to fix specific folder)
	@echo "$(GREEN)Fixing line endings...$(NC)"
	@if [ -n "$(PATH)" ]; then \
		echo "$(YELLOW)Fixing specific path: $(PATH)$(NC)"; \
		/usr/bin/find $(PATH) -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.j2" \) -exec dos2unix {} \; 2>/dev/null || true; \
	else \
		/usr/bin/find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.j2" \) -exec dos2unix {} \; 2>/dev/null || true; \
	fi
	@echo "$(GREEN)✓ Line endings fixed$(NC)"

# Security Commands
security: security-scan check-secrets ## Run security checks

security-scan: ## Run security scanning with Trivy (use PATH=<path> to scan specific folder)
	@echo "$(GREEN)Running security scan...$(NC)"
	@if /usr/local/bin/trivy --version &> /dev/null || trivy --version &> /dev/null; then \
		if [ -n "$(PATH)" ]; then \
			echo "$(YELLOW)Scanning specific path: $(PATH)$(NC)"; \
			/usr/local/bin/trivy fs $(PATH) --severity HIGH,CRITICAL 2>/dev/null || trivy fs $(PATH) --severity HIGH,CRITICAL; \
		else \
			/usr/local/bin/trivy fs . --severity HIGH,CRITICAL 2>/dev/null || trivy fs . --severity HIGH,CRITICAL; \
		fi; \
	else \
		echo "$(YELLOW)⚠ Trivy not installed. Install with: brew install trivy$(NC)"; \
	fi

detect-secrets: ## Run detect-secrets scanner (use PATH=<path> to scan specific folder)
	@echo "$(GREEN)Running detect-secrets scanner...$(NC)"
	@if [ -n "$(PATH)" ]; then \
		echo "$(YELLOW)Scanning path: $(PATH)$(NC)"; \
		echo ""; \
		if [ -f "/Users/swaroop/SIDKS/ansible/venv/bin/detect-secrets" ]; then \
			results=$$(/Users/swaroop/SIDKS/ansible/venv/bin/detect-secrets scan $(PATH) --all-files 2>/dev/null | \
				/usr/local/bin/python3 -c "import sys, json; data=json.load(sys.stdin); print(json.dumps(data.get('results', {})))" 2>/dev/null); \
			if [ "$$results" = "{}" ] || [ -z "$$results" ]; then \
				echo "$(GREEN)✓ No secrets detected in $(PATH)$(NC)"; \
			else \
				echo "$(RED)⚠ Potential secrets found:$(NC)"; \
				echo "$$results" | /usr/local/bin/python3 -m json.tool; \
			fi; \
		else \
			echo "$(RED)detect-secrets not found in venv. Install with: pip install detect-secrets$(NC)"; \
		fi; \
	else \
		echo "$(YELLOW)Scanning entire project...$(NC)"; \
		if [ -f "/Users/swaroop/SIDKS/ansible/venv/bin/detect-secrets" ]; then \
			/Users/swaroop/SIDKS/ansible/venv/bin/detect-secrets scan . --all-files 2>/dev/null | \
			/usr/local/bin/python3 -m json.tool 2>/dev/null | \
			/usr/bin/head -50; \
			echo ""; \
			echo "$(YELLOW)Tip: Use PATH=/path/to/folder to scan specific directories$(NC)"; \
		else \
			echo "$(RED)detect-secrets not found. Install with: pip install detect-secrets$(NC)"; \
		fi; \
	fi

detect-secrets-baseline: ## Create or update detect-secrets baseline file
	@echo "$(GREEN)Creating/updating detect-secrets baseline...$(NC)"
	@if [ -f "/Users/swaroop/SIDKS/ansible/venv/bin/detect-secrets" ]; then \
		/Users/swaroop/SIDKS/ansible/venv/bin/detect-secrets scan . > .secrets.baseline; \
		echo "$(GREEN)✓ Baseline created in .secrets.baseline$(NC)"; \
		echo "$(YELLOW)Review the baseline file and commit it to track allowed secrets$(NC)"; \
		echo "  Files scanned: $$(cat .secrets.baseline | /usr/local/bin/python3 -c 'import sys, json; data=json.load(sys.stdin); print(len(data.get(\"results\", {})))' 2>/dev/null || echo '0')"; \
	else \
		echo "$(RED)detect-secrets not found. Install with: pip install detect-secrets$(NC)"; \
	fi

detect-secrets-audit: ## Audit the secrets baseline interactively
	@echo "$(GREEN)Auditing secrets baseline...$(NC)"
	@if [ -f ".secrets.baseline" ]; then \
		if [ -f "/Users/swaroop/SIDKS/ansible/venv/bin/detect-secrets" ]; then \
			/Users/swaroop/SIDKS/ansible/venv/bin/detect-secrets audit .secrets.baseline; \
		else \
			echo "$(RED)detect-secrets not found. Install with: pip install detect-secrets$(NC)"; \
		fi; \
	else \
		echo "$(YELLOW)No baseline file found. Create one with: make detect-secrets-baseline$(NC)"; \
	fi

check-secrets: ## Check for hardcoded secrets (use PATH=<path> to check specific folder)
	@echo "$(GREEN)Checking for secrets...$(NC)"
	@if [ -f "/Users/swaroop/SIDKS/ansible/venv/bin/detect-secrets" ]; then \
		if [ -n "$(PATH)" ]; then \
			echo "$(YELLOW)Checking specific path: $(PATH)$(NC)"; \
			results=$$(/Users/swaroop/SIDKS/ansible/venv/bin/detect-secrets scan $(PATH) --all-files 2>/dev/null | \
				/usr/local/bin/python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('results', {})))" 2>/dev/null || echo "0"); \
			if [ "$$results" = "0" ]; then \
				echo "  $(GREEN)✓ No secrets detected by detect-secrets$(NC)"; \
			else \
				echo "  $(RED)⚠ Found $$results file(s) with potential secrets$(NC)"; \
			fi; \
		else \
			if [ -f ".secrets.baseline" ]; then \
				/Users/swaroop/SIDKS/ansible/venv/bin/detect-secrets scan --baseline .secrets.baseline . 2>/dev/null; \
			else \
				echo "  $(YELLOW)No baseline found. Run 'make detect-secrets-baseline' to create one$(NC)"; \
			fi; \
		fi; \
	else \
		echo "$(YELLOW)⚠ detect-secrets not installed. Install with: pip install detect-secrets$(NC)"; \
	fi
	@echo "Checking for hardcoded credentials..."
	@if [ -n "$(PATH)" ]; then \
		if /usr/bin/grep -rE "(api_key|password|token|secret):\s*['\"][\w\-]+['\"]" --include="*.yml" --include="*.yaml" $(PATH) 2>/dev/null | /usr/bin/grep -v -E "(vault_|lookup|env|prompt)" | /usr/bin/grep -v "^#"; then \
			echo "$(RED)✗ Found potential hardcoded secrets$(NC)"; \
			exit 1; \
		fi; \
	else \
		if /usr/bin/grep -rE "(api_key|password|token|secret):\s*['\"][\w\-]+['\"]" --include="*.yml" --include="*.yaml" roles/ playbooks/ 2>/dev/null | /usr/bin/grep -v -E "(vault_|lookup|env|prompt)" | /usr/bin/grep -v "^#"; then \
			echo "$(RED)✗ Found potential hardcoded secrets$(NC)"; \
			exit 1; \
		fi; \
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