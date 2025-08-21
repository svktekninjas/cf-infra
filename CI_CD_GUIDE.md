# CI/CD and Code Quality Guide for Ansible

This guide explains how to use the CI/CD pipeline and code quality tools to catch issues before runtime.

## Table of Contents
- [Quick Start](#quick-start)
- [Tools Overview](#tools-overview)
- [Local Development](#local-development)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [Common Issues and Fixes](#common-issues-and-fixes)
- [Best Practices](#best-practices)

## Quick Start

### Initial Setup
```bash
# Install all dependencies
make setup

# Run all checks locally
make all

# Fix common issues automatically
make fix
```

### Before Committing
```bash
# Run pre-commit hooks
make pre-commit

# Or let git run them automatically
git commit -m "Your message"  # pre-commit runs automatically
```

## Tools Overview

### 1. **YAML Lint**
- **Purpose**: Validates YAML syntax and formatting
- **Config**: `.yamllint`
- **Run**: `make yaml-lint`
- **Catches**: Indentation errors, line length, syntax issues

### 2. **Ansible Lint**
- **Purpose**: Checks Ansible best practices and common issues
- **Config**: `.ansible-lint`
- **Run**: `make ansible-lint`
- **Catches**: 
  - Undefined variables
  - Reserved variable names (like `environment`)
  - Missing FQCN for modules
  - Security issues
  - Deprecated syntax

### 3. **Pre-commit Hooks**
- **Purpose**: Automated checks before git commits
- **Config**: `.pre-commit-config.yaml`
- **Install**: `pre-commit install`
- **Includes**:
  - YAML/JSON validation
  - Ansible linting
  - Secret detection
  - Shell script checking
  - Trailing whitespace removal

### 4. **GitHub Actions**
- **Purpose**: CI/CD pipeline for PRs and commits
- **Config**: `.github/workflows/ansible-ci.yml`
- **Jobs**:
  - YAML linting
  - Ansible linting
  - Syntax checking
  - Security scanning
  - Variable validation
  - Documentation checking

## Local Development

### Using the Makefile

```bash
# Install dependencies
make install

# Run all linters
make lint

# Validate everything
make validate

# Run security checks
make security

# Auto-fix issues
make fix

# Run local CI pipeline (mimics GitHub Actions)
make ci-local

# Generate quality report
make report
```

### Manual Commands

```bash
# YAML Lint
yamllint -c .yamllint .

# Ansible Lint
ansible-lint --force-color

# Syntax Check
ansible-playbook playbooks/setup-harness.yml --syntax-check

# Pre-commit on all files
pre-commit run --all-files

# Update pre-commit hooks
pre-commit autoupdate
```

## GitHub Actions CI/CD

### Pipeline Triggers
- **Push**: to main, develop, feature/* branches
- **Pull Request**: to main, develop
- **Manual**: via workflow_dispatch

### CI Jobs

1. **yaml-lint**: Validates YAML formatting
2. **ansible-lint**: Checks Ansible best practices
3. **ansible-syntax**: Validates playbook syntax
4. **security-scan**: Scans for vulnerabilities
5. **variable-validation**: Checks variables
6. **documentation-check**: Ensures docs exist
7. **summary**: Generates reports

### PR Comments
The pipeline automatically comments on PRs with results:
```
🤖 Ansible CI Results

| Check | Status |
|-------|--------|
| YAML Lint | ✅ |
| Ansible Lint | ✅ |
| Syntax Check | ✅ |
| Security | ✅ |
| Variables | ✅ |
| Docs | ✅ |
```

## Common Issues and Fixes

### Issue 1: Reserved Variable Name 'environment'
```yaml
# ❌ Wrong
environment: "{{ env }}"

# ✅ Correct
target_environment: "{{ env }}"
```

### Issue 2: Variable Type Mismatch
```yaml
# ❌ Wrong - environment is a list
environment: []
...
labels:
  environment: "{{ environment }}"  # Can't use list as string

# ✅ Correct
target_environment: "dev"
...
labels:
  environment: "{{ target_environment }}"
```

### Issue 3: Undefined Variables
```yaml
# ❌ Wrong - using undefined variable
- name: Use undefined var
  debug:
    msg: "{{ undefined_variable }}"

# ✅ Correct - define in defaults/main.yml
undefined_variable: "default_value"
```

### Issue 4: YAML Formatting
```yaml
# ❌ Wrong - inconsistent indentation
tasks:
- name: Task 1
   debug:
     msg: "test"

# ✅ Correct - consistent 2-space indentation
tasks:
  - name: Task 1
    debug:
      msg: "test"
```

### Issue 5: Hardcoded Secrets
```yaml
# ❌ Wrong
api_key: "sk-1234567890abcdef"

# ✅ Correct
api_key: "{{ vault_api_key }}"
```

## Best Practices

### 1. Variable Naming
- Use lowercase with underscores: `my_variable_name`
- Avoid reserved names: `environment`, `action`, `role`
- Prefix vault variables: `vault_secret_name`
- Use descriptive names: `aws_region` not `region`

### 2. Task Naming
- Start with capital letter
- Use present tense
- Be descriptive
```yaml
# ✅ Good
- name: Install Docker prerequisites
- name: Configure firewall rules
- name: Start and enable nginx service
```

### 3. File Organization
```
roles/
├── role-name/
│   ├── defaults/main.yml    # Default variables
│   ├── vars/main.yml        # Role variables
│   ├── tasks/main.yml       # Tasks
│   ├── handlers/main.yml    # Handlers
│   ├── templates/           # Jinja2 templates
│   ├── files/              # Static files
│   └── README.md           # Documentation
```

### 4. Error Handling
```yaml
# Use failed_when for custom failure conditions
- name: Check service status
  command: systemctl status myservice
  register: service_status
  failed_when: 
    - service_status.rc != 0
    - "'active' not in service_status.stdout"

# Use changed_when for idempotency
- name: Run configuration script
  command: /opt/configure.sh
  register: config_result
  changed_when: "'CHANGED' in config_result.stdout"
```

### 5. Security
- Never commit secrets
- Use Ansible Vault for sensitive data
- Use `no_log: true` for sensitive tasks
- Validate input variables
- Use least privilege for service accounts

## Troubleshooting

### Running Specific Checks
```bash
# Check only specific file
yamllint playbooks/setup-harness.yml

# Check only specific role
ansible-lint roles/cf-harness/

# Test specific pre-commit hook
pre-commit run yamllint --all-files
```

### Debugging CI Failures
```bash
# Run with verbose output
ansible-lint -vvv

# Check specific rule
ansible-lint --tags deprecated

# Generate detailed report
make report
```

### Fixing Issues
```bash
# Auto-fix YAML formatting
make fix-yaml

# Fix line endings
make fix-line-endings

# Fix file permissions
make fix-permissions
```

## Integration with IDEs

### VS Code
Install extensions:
- `redhat.ansible`
- `redhat.vscode-yaml`

Add to `.vscode/settings.json`:
```json
{
  "ansible.validation.enabled": true,
  "ansible.validation.lint.enabled": true,
  "yaml.schemas": {
    "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json": "*.yml"
  }
}
```

### PyCharm
- Install Ansible plugin
- Configure: Settings → Tools → Ansible
- Enable: Settings → Editor → Inspections → Ansible

## Monitoring Quality

### Metrics to Track
- Linting errors/warnings count
- Code coverage (if using Molecule)
- Security vulnerabilities found
- Documentation completeness
- PR approval time

### Quality Gates
Set these thresholds:
- Zero critical linting errors
- Zero security vulnerabilities (HIGH/CRITICAL)
- All playbooks must pass syntax check
- Documentation required for all roles

## Continuous Improvement

1. **Regular Updates**
   ```bash
   # Update tools
   pip install --upgrade ansible-lint yamllint
   
   # Update pre-commit hooks
   pre-commit autoupdate
   ```

2. **Review Reports**
   - Check GitHub Actions summary
   - Review `quality-report.md`
   - Monitor trends over time

3. **Team Training**
   - Share common issues
   - Document patterns
   - Review PR feedback

## Resources

- [Ansible Lint Documentation](https://ansible-lint.readthedocs.io/)
- [YAML Lint Documentation](https://yamllint.readthedocs.io/)
- [Pre-commit Documentation](https://pre-commit.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

---

**Remember**: The goal is to catch issues early and maintain consistent, high-quality code across the team!