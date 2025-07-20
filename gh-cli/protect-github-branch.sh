#!/bin/bash
# Usage: ./protect-github-branch.sh <owner> <repo> <branch>
# Example: ./protect-github-branch.sh moovendhan-v PgQueryBuilder master

OWNER="$1"
REPO="$2"
BRANCH="$3"

if [[ -z "$OWNER" || -z "$REPO" || -z "$BRANCH" ]]; then
    echo "Usage: $0 <owner> <repo> <branch>"
    exit 1
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "❌ Error: 'jq' is required but not installed. Install it (e.g., 'brew install jq' on macOS)."
    exit 1
fi

# Make repo public (requires --accept-visibility-change-consequences)
echo "📢 Making $OWNER/$REPO public..."
gh repo edit "$OWNER/$REPO" --visibility=public --accept-visibility-change-consequences || echo "⚠️ Failed to make repository public. It may already be public or you lack permissions."

# Check if CODEOWNERS exists; if not, create via pull request
echo "👥 Pre-checking for CODEOWNERS file..."
if ! gh api "/repos/$OWNER/$REPO/contents/.github/CODEOWNERS" > /dev/null 2>&1; then
    echo "📝 Creating CODEOWNERS file via pull request..."
    TEMP_BRANCH="add-codeowners-$(date +%s)"
    gh api -X POST \
        -H "Accept: application/vnd.github+json" \
        "/repos/$OWNER/$REPO/git/refs" \
        --input - << EOF
{
  "ref": "refs/heads/$TEMP_BRANCH",
  "sha": "$(gh api "/repos/$OWNER/$REPO/git/ref/heads/$BRANCH" | jq -r .object.sha)"
}
EOF

    # Create .github directory if it doesn't exist
    gh api \
        -X PUT \
        -H "Accept: application/vnd.github+json" \
        "/repos/$OWNER/$REPO/contents/.github/.gitkeep" \
        --input - << EOF
{
  "message": "Create .github directory",
  "content": "$(echo "" | base64)",
  "branch": "$TEMP_BRANCH"
}
EOF
    
    # Create CODEOWNERS file
    gh api \
        -X PUT \
        -H "Accept: application/vnd.github+json" \
        "/repos/$OWNER/$REPO/contents/.github/CODEOWNERS" \
        --input - << EOF
{
  "message": "Add CODEOWNERS file for repository security",
  "content": "$(printf "# Global code owners\n* @$OWNER\n\n# Specific file protections\n*.yml @$OWNER\n*.yaml @$OWNER\n*.json @$OWNER\nDockerfile* @$OWNER\n.github/ @$OWNER\n*.sh @$OWNER\n*.py @$OWNER" | base64)",
  "branch": "$TEMP_BRANCH"
}
EOF

    # Create pull request
    gh api \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        "/repos/$OWNER/$REPO/pulls" \
        --input - << EOF
{
  "title": "Add CODEOWNERS file",
  "body": "Automatically generated CODEOWNERS file for repository security.",
  "head": "$TEMP_BRANCH",
  "base": "$BRANCH"
}
EOF
else
    echo "✓ CODEOWNERS file already exists"
fi

# Check if SECURITY.md exists; if not, create via pull request
echo "📜 Checking for SECURITY.md file..."
if ! gh api "/repos/$OWNER/$REPO/contents/SECURITY.md" > /dev/null 2>&1; then
    echo "📝 Creating SECURITY.md file via pull request..."
    TEMP_BRANCH="add-security-md-$(date +%s)"
    gh api -X POST \
        -H "Accept: application/vnd.github+json" \
        "/repos/$OWNER/$REPO/git/refs" \
        --input - << EOF
{
  "ref": "refs/heads/$TEMP_BRANCH",
  "sha": "$(gh api "/repos/$OWNER/$REPO/git/ref/heads/$BRANCH" | jq -r .object.sha)"
}
EOF

    gh api \
        -X PUT \
        -H "Accept: application/vnd.github+json" \
        "/repos/$OWNER/$REPO/contents/SECURITY.md" \
        --input - << EOF
{
  "message": "Add SECURITY.md file for vulnerability reporting",
  "content": "$(printf "# Security Policy\n\n## Reporting a Vulnerability\n\nPlease report security vulnerabilities by emailing @$OWNER or opening a private issue in this repository. We will respond within 48 hours and work with you to address the issue promptly.\n\n## Supported Versions\n\nWe provide security updates for the latest release and the main branch.\n" | base64)",
  "branch": "$TEMP_BRANCH"
}
EOF

    gh api \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        "/repos/$OWNER/$REPO/pulls" \
        --input - << EOF
{
  "title": "Add SECURITY.md file",
  "body": "Automatically generated SECURITY.md file for vulnerability reporting.",
  "head": "$TEMP_BRANCH",
  "base": "$BRANCH"
}
EOF
else
    echo "✓ SECURITY.md file already exists"
fi

# Check if CodeQL workflow exists; if not, create via pull request
echo "🔍 Checking for CodeQL workflow..."
if ! gh api "/repos/$OWNER/$REPO/contents/.github/workflows/codeql-analysis.yml" > /dev/null 2>&1; then
    echo "📝 Creating CodeQL workflow via pull request..."
    TEMP_BRANCH="add-codeql-$(date +%s)"
    gh api -X POST \
        -H "Accept: application/vnd.github+json" \
        "/repos/$OWNER/$REPO/git/refs" \
        --input - << EOF
{
  "ref": "refs/heads/$TEMP_BRANCH",
  "sha": "$(gh api "/repos/$OWNER/$REPO/git/ref/heads/$BRANCH" | jq -r .object.sha)"
}
EOF

    gh api \
        -X PUT \
        -H "Accept: application/vnd.github+json" \
        "/repos/$OWNER/$REPO/contents/.github/workflows/codeql-analysis.yml" \
        --input - << EOF
{
  "message": "Add CodeQL analysis workflow",
  "content": "$(printf "name: CodeQL\n\non:\n  push:\n    branches: [ \"$BRANCH\" ]\n  pull_request:\n    branches: [ \"$BRANCH\" ]\n  schedule:\n    - cron: '0 0 * * 0'\n\njobs:\n  analyze:\n    name: Analyze\n    runs-on: ubuntu-latest\n    permissions:\n      actions: read\n      contents: read\n      security-events: write\n\n    strategy:\n      fail-fast: false\n      matrix:\n        language: [ 'javascript', 'python', 'ruby', 'go', 'cpp', 'csharp', 'java', 'swift' ]\n\n    steps:\n    - name: Checkout repository\n      uses: actions/checkout@v3\n\n    - name: Initialize CodeQL\n      uses: github/codeql-action/init@v3\n      with:\n        languages: \${{ matrix.language }}\n\n    - name: Autobuild\n      uses: github/codeql-action/autobuild@v3\n\n    - name: Perform CodeQL Analysis\n      uses: github/codeql-action/analyze@v3\n" | base64)",
  "branch": "$TEMP_BRANCH"
}
EOF

    gh api \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        "/repos/$OWNER/$REPO/pulls" \
        --input - << EOF
{
  "title": "Add CodeQL analysis workflow",
  "body": "Automatically generated CodeQL workflow for security scanning.",
  "head": "$TEMP_BRANCH",
  "base": "$BRANCH"
}
EOF
else
    echo "✓ CodeQL workflow already exists"
fi

# Apply branch protection with enhanced security, allowing admin direct commits
echo "🔒 Applying enhanced branch protection rules to '$BRANCH'..."
gh api \
    -X PUT \
    -H "Accept: application/vnd.github+json" \
    "/repos/$OWNER/$REPO/branches/$BRANCH/protection" \
    --input - << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["ci/test", "lint", "build", "CodeQL"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 2,
    "require_last_push_approval": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
EOF

# Enable additional security features
echo "🛡️ Enabling additional security features..."

# Enable vulnerability alerts
echo "🔍 Enabling vulnerability alerts..."
gh api \
    -X PUT \
    -H "Accept: application/vnd.github+json" \
    "/repos/$OWNER/$REPO/vulnerability-alerts" || echo "⚠️ Vulnerability alerts may already be enabled or unavailable"

# Enable automated security fixes
echo "🔧 Enabling automated security fixes..."
gh api \
    -X PUT \
    -H "Accept: application/vnd.github+json" \
    "/repos/$OWNER/$REPO/automated-security-fixes" || echo "⚠️ Automated security fixes may already be enabled or unavailable"

# Enable dependency graph and security updates
echo "📊 Enabling dependency graph and security updates..."
gh api \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    "/repos/$OWNER/$REPO" \
    --input - << 'EOF'
{
  "has_vulnerability_alerts_enabled": true,
  "security_and_analysis": {
    "dependency_graph": {
      "status": "enabled"
    },
    "dependabot_security_updates": {
      "status": "enabled"
    }
  }
}
EOF

# Enable secret scanning push protection
echo "🔐 Enabling secret scanning push protection..."
gh api \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    "/repos/$OWNER/$REPO" \
    --input - << 'EOF'
{
  "security_and_analysis": {
    "secret_scanning": {
      "status": "enabled"
    },
    "secret_scanning_push_protection": {
      "status": "enabled"
    }
  }
}
EOF || echo "⚠️ Secret scanning push protection may not be available (requires GitHub Advanced Security or specific permissions)"

# Enable dependency review
echo "📦 Enabling dependency review..."
gh api \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    "/repos/$OWNER/$REPO" \
    --input - << 'EOF'
{
  "security_and_analysis": {
    "dependency_graph": {
      "status": "enabled"
    },
    "dependency_review": {
      "status": "enabled"
    }
  }
}
EOF || echo "⚠️ Dependency review may not be available"

# Final verification
echo "🎉 Repository setup complete!"
echo "✅ Security features enabled:"
echo "   - Vulnerability alerts"
echo "   - Automated security fixes"
echo "   - Dependency graph"
echo "   - Secret scanning with push protection (if available)"
echo "   - CodeQL code scanning (via workflow PR)"
echo "   - Dependency review (if available)"
echo "   - SECURITY.md file for vulnerability reporting"
echo "✅ Branch protection active:"
echo "   - Admins can commit directly"
echo "   - 2 required reviewers for non-admins"
echo "   - Code owner approval required"
echo "   - Linear history enforced"
echo "   - Force pushes blocked"
echo "   - Required status checks (ci/test, lint, build, CodeQL)"

echo "✅ Branch '$BRANCH' is now protected. Admins can commit directly; others must use PRs."
echo "📌 Check open pull requests to merge CODEOWNERS, SECURITY.md, and CodeQL workflow files."