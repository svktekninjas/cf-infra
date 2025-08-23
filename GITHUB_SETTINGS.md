# GitHub Repository Settings Required

## Permissions for GitHub Actions

For the CI/CD pipeline to work correctly, ensure the following settings are configured in your GitHub repository:

### 1. Actions Permissions
Go to: **Settings > Actions > General**

- **Actions permissions**: Allow all actions and reusable workflows
- **Workflow permissions**: 
  - ✅ Read and write permissions
  - ✅ Allow GitHub Actions to create and approve pull requests

### 2. Code Security Settings
Go to: **Settings > Code security and analysis**

Enable the following:
- ✅ Dependency graph
- ✅ Dependabot alerts
- ✅ Dependabot security updates
- ✅ Code scanning (if available in your plan)
- ✅ Secret scanning (if available in your plan)

### 3. Branch Protection Rules (Optional but Recommended)
Go to: **Settings > Branches**

For the `main` branch:
- ✅ Require pull request reviews before merging
- ✅ Require status checks to pass before merging
  - Required status checks:
    - `yaml-lint`
    - `ansible-lint`
    - `ansible-syntax`
- ✅ Require branches to be up to date before merging
- ✅ Include administrators

## GitHub Actions Workflow Permissions

The workflow includes these permissions at the top level:

```yaml
permissions:
  contents: read        # Read repository contents
  security-events: write # Upload security scan results
  pull-requests: write  # Comment on PRs
  actions: read        # Read workflow runs
```

## Troubleshooting

### "Resource not accessible by integration" Error

If you see this error when uploading SARIF results:
1. Check that your repository has GitHub Advanced Security enabled (required for private repos)
2. For public repos, code scanning should be available by default
3. The workflow now includes `continue-on-error: true` for SARIF upload to prevent workflow failure

### Alternative Security Scanning

If SARIF upload isn't available for your repository:
- The workflow will still run Trivy in table format
- Security results will be visible in the workflow logs
- Consider using third-party security scanning services if needed

## Required Secrets

No secrets are required for the basic CI/CD pipeline. However, if you plan to deploy or push images, you may need:

- `AWS_ACCESS_KEY_ID` - For AWS operations
- `AWS_SECRET_ACCESS_KEY` - For AWS operations
- `DOCKERHUB_TOKEN` - For Docker image pushes
- `HARNESS_API_KEY` - For Harness deployments

Add these in: **Settings > Secrets and variables > Actions**