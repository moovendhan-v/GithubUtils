# GitHub Branch Protection Script

# GitHub Branch Protection Script

This Bash script automates the setup of enhanced branch protection and security features for a specified GitHub repository branch. It configures repository visibility, creates necessary security files via pull requests, applies strict branch protection rules, and enables GitHub security features like secret scanning, CodeQL, and dependency review.

## Features

* Makes the repository public (if not already).
* Creates or verifies a `.github/CODEOWNERS` file via a pull request.
* Creates a `SECURITY.md` file for vulnerability reporting via a pull request.
* Creates a GitHub Actions workflow for CodeQL code scanning via a pull request.
* Applies strict branch protection rules:
  * Allows admins to commit directly.
  * Requires 2 approving reviews for non-admins.
  * Mandates code owner reviews.
  * Enforces linear history.
  * Blocks force pushes and branch deletions.
  * Requires conversation resolution and status checks (`ci/test`, `lint`, `build`, `CodeQL`).
* Enables GitHub security features (where available):
  * Vulnerability alerts.
  * Automated security fixes.
  * Dependency graph and Dependabot security updates.
  * Secret scanning with push protection.
  * Dependency review.

## Prerequisites

* **GitHub CLI (`gh`)**: Installed and authenticated with a token that has `repo` and `admin:repo_hook` scopes.
* **jq**: Installed for JSON parsing (`brew install jq` on macOS or equivalent).
* Admin permissions for the target repository.
* For private repositories, a **GitHub Team** or **Enterprise** plan with a **GitHub Advanced Security** license is required for features like secret scanning push protection and dependency review.

## Usage

```bash
./protect-github-branch.sh <owner> <repo> <branch>
```

### Example

```bash
./protect-github-branch.sh moovendhan-v PgQueryBuilder master
```

This command will:

1. Set the `PgQueryBuilder` repository owned by `moovendhan-v` to public.
2. Create pull requests for `CODEOWNERS`, `SECURITY.md`, and a CodeQL workflow.
3. Apply protection rules to the `master` branch, allowing admins to commit directly.
4. Enable available security features.

## Arguments

* `<owner>`: GitHub username or organization name.
* `<repo>`: Repository name.
* `<branch>`: Branch to protect (e.g., `main`, `master`).

## Configuration Details

### CODEOWNERS File

If no `CODEOWNERS` file exists, the script creates one with:

```
# Global code owners
* @<owner>

# Specific file protections
*.yml @<owner>
*.yaml @<owner>
*.json @<owner>
Dockerfile* @<owner>
.github/ @<owner>
*.sh @<owner>
*.py @<owner>
```

### SECURITY.md File

If no `SECURITY.md` file exists, the script creates one with:

```markdown
# Security Policy

## Reporting a Vulnerability

Please report security vulnerabilities by emailing @<owner> or opening a private issue in this repository. We will respond within 48 hours and work with you to address the issue promptly.

## Supported Versions

We provide security updates for the latest release and the main branch.
```

### CodeQL Workflow

If no CodeQL workflow exists, the script creates `.github/workflows/codeql-analysis.yml` to scan for vulnerabilities in multiple languages (`javascript`, `python`, `ruby`, `go`, `cpp`, `csharp`, `java`, `swift`) on push, pull requests, and a weekly schedule.

### Branch Protection

* **Admins**: Can commit directly (`enforce_admins: false`).
* **Non-Admins**: Require pull requests with 2 approvals, code owner review, and resolved conversations.
* **Status Checks**: Requires passing `ci/test`, `lint`, `build`, and `CodeQL` workflows.
* **Other Rules**: Enforces linear history, blocks force pushes and deletions.

### Security Features

* **Public Repositories**: Features like secret scanning, push protection, and CodeQL are free and enabled by default or via the script.
* **Private Repositories**: Require a GitHub Advanced Security license (available with Team or Enterprise plans).

## Post-Execution Steps

1. **Merge Pull Requests**: Check the repository for open pull requests (`CODEOWNERS`, `SECURITY.md`, `codeql-analysis.yml`) and merge them via the GitHub UI.
2. **Verify Security Settings**: Go to `Settings > Security & analysis` in the GitHub UI to confirm enabled features.
3. **Check Status Checks**: Ensure `ci/test`, `lint`, `build`, and `CodeQL` workflows exist in your repository. Update the script’s `contexts` array if your workflows have different names.

## Troubleshooting

* **HTTP 404 Errors (Secret Scanning/CodeQL)**:
  * For public repositories, these features should be available. Verify in `Settings > Security & analysis`.
  * For private repositories, ensure a GitHub Advanced Security license is active (Team or Enterprise plan).
  * Check your `gh` CLI token scopes: `gh auth status`. Regenerate with `repo` and `admin:repo_hook` scopes if needed.
* **Permission Errors**: Ensure the authenticated user has admin access to the repository.
* **Missing `jq`**: Install `jq` (`brew install jq` on macOS).
* **Pull Request Creation**: If file creation fails due to branch protection, the script creates pull requests. Merge them to apply changes.
* **Contact GitHub Support**: If features are unavailable, file a support ticket at `https://support.github.com`.

## Notes

* **Public Repositories**: Secret scanning and push protection are enabled by default. The script verifies and enables them if needed.
* **Private Repositories**: Require a GitHub Advanced Security license for some features. Check pricing at `https://github.com/pricing`.
* **CI/CD Workflows**: Update the `required_status_checks.contexts` array in the script to match your repository’s workflow names.
* **Testing**: Test the script in a non-critical repository first to avoid unintended changes.

This Bash script automates the process of setting up enhanced branch protection and security features for a specified GitHub repository branch. It configures repository visibility, creates a CODEOWNERS file if needed, applies strict branch protection rules, and enables various GitHub security features.

## Features

* Makes the repository public
* Creates or verifies a `.github/CODEOWNERS` file
* Applies strict branch protection rules:
  * Requires pull request reviews with at least 2 approvals
  * Mandates code owner reviews
  * Enforces linear history
  * Blocks force pushes and branch deletions
  * Requires conversation resolution before merging
* Enables GitHub security features:
  * Vulnerability alerts
  * Automated security fixes
  * Dependency graph

## Prerequisites

* GitHub CLI (`gh`) installed and authenticated
* Appropriate permissions to manage the target repository
* Bash environment

## Usage

```bash
./protect-github-branch.sh <owner> <repo> <branch>
```

### Example

```bash
./protect-github-branch.sh moovendhan-v PgQueryBuilder master
```

This command will:

1. Set the `PgQueryBuilder` repository owned by `moovendhan-v` to public
2. Create or verify a CODEOWNERS file
3. Apply protection rules to the `master` branch
4. Enable security features for the repository

## Arguments

* `<owner>`: GitHub username or organization name
* `<repo>`: Repository name
* `<branch>`: Branch to protect (e.g., `main`, `master`)

## CODEOWNERS Configuration

If no CODEOWNERS file exists, the script creates one with the following rules:

```
# Global code owners
* @<owner>

# Specific file protections
*.yml @<owner>
*.yaml @<owner>
*.json @<owner>
Dockerfile* @<owner>
.github/ @<owner>
*.sh @<owner>
*.py @<owner>
```

## Security Features Enabled

* **Vulnerability Alerts**: Detects and alerts for known vulnerabilities
* **Automated Security Fixes**: Automatically creates PRs for security updates
* **Dependency Graph**: Tracks and manages dependencies
* **Branch Protection**:
  * Requires 2 approving reviews
  * Requires code owner approval
  * Enforces linear history
  * Prevents force pushes
  * Prevents branch deletion
  * Requires conversation resolution

## Notes

* Ensure you have the necessary permissions to modify repository settings
* The script uses the GitHub API via the `gh` CLI tool
* The repository must exist before running the script
* Backup important data before running, as some changes (like making the repo public) are significant

## Troubleshooting

* **Authentication errors**: Verify `gh` CLI is authenticated (`gh auth login`)
* **Permission errors**: Ensure you have admin access to the repository
* **API rate limits**: Check GitHub API rate limits if requests fail
* **Missing CODEOWNERS**: The script will create one if it doesn't exist
