#!/usr/bin/env bash
# Pre-commit security scan
# Usage: bash scan.sh [directory]
# Scans for hardcoded secrets, dangerous patterns, and tracked sensitive files.

set -euo pipefail

DIR="${1:-.}"
FOUND_ISSUES=0

echo "=== Security Scan ==="
echo ""

# 1. Search for potential hardcoded secrets
echo "--- Potential hardcoded secrets ---"
if grep -rn "api_key\|api_secret\|password\|token\|secret" \
    --include="*.py" --include="*.js" --include="*.ts" --include="*.env" \
    "$DIR" 2>/dev/null | grep -v node_modules | grep -v ".git/"; then
    FOUND_ISSUES=1
else
    echo "(none found)"
fi
echo ""

# 2. Search for dangerous code patterns
echo "--- Dangerous patterns (shell=True, eval, innerHTML, etc.) ---"
if grep -rn "shell=True\|eval(\|exec(\|innerHTML\|document.write" \
    --include="*.py" --include="*.js" --include="*.ts" \
    "$DIR" 2>/dev/null | grep -v node_modules; then
    FOUND_ISSUES=1
else
    echo "(none found)"
fi
echo ""

# 3. Check for sensitive files tracked by git
echo "--- Sensitive files in git tracking ---"
if git ls-files 2>/dev/null | grep -i "\.env\|credentials\|secret\|\.pem\|\.key"; then
    FOUND_ISSUES=1
else
    echo "(none found)"
fi
echo ""

# 4. Search for private key headers
echo "--- Private key material ---"
if grep -rn "\-\-\-\-\-BEGIN" \
    --include="*.py" --include="*.js" --include="*.ts" --include="*.pem" --include="*.key" \
    "$DIR" 2>/dev/null | grep -v node_modules | grep -v ".git/"; then
    FOUND_ISSUES=1
else
    echo "(none found)"
fi
echo ""

if [ "$FOUND_ISSUES" -eq 1 ]; then
    echo "⚠  Issues found — review above before committing."
    exit 1
else
    echo "✓  No issues found."
    exit 0
fi
