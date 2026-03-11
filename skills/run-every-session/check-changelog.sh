#!/usr/bin/env bash
# Stop hook: Block Claude from stopping if a changelog is missing for the current feature branch.
# Receives JSON on stdin with stop_hook_active field.
# Outputs JSON {"decision":"block","reason":"..."} to prevent stopping.

set -euo pipefail

# Read stdin (Stop hook input JSON)
INPUT=$(cat 2>/dev/null || echo '{}')

# If already triggered by a previous stop hook, don't block again (avoid infinite loop)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('stop_hook_active', False))" 2>/dev/null || echo "False")
if [ "$STOP_HOOK_ACTIVE" = "True" ]; then
  exit 0
fi

MISSING_BRANCH=""
MISSING_WT_PATH=""

# Check all git worktrees for missing changelogs
while IFS= read -r line; do
  WT_PATH=$(echo "$line" | awk '{print $1}')
  WT_BRANCH=$(echo "$line" | sed -n 's/.*\[\(.*\)\].*/\1/p')

  # Skip main/master/empty/detached
  case "$WT_BRANCH" in
    main|master|""|HEAD) continue ;;
  esac

  # Skip if not a .worktrees path (it's the main checkout)
  echo "$WT_PATH" | grep -q '\.worktrees' || continue

  # Check for commits beyond master
  COMMITS=$(git -C "$WT_PATH" log master..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
  [ "$COMMITS" = "0" ] && continue

  # Sanitize branch name for filename matching (feat/foo -> feat-foo)
  BRANCH_SLUG=$(echo "$WT_BRANCH" | tr '/' '-')

  # Check if any changelog file exists matching this branch slug
  if ! ls "$WT_PATH"/docs/changelogs/*"${BRANCH_SLUG}"* 1>/dev/null 2>&1; then
    MISSING_BRANCH="$WT_BRANCH"
    MISSING_WT_PATH="$WT_PATH"
    break
  fi
done < <(git worktree list 2>/dev/null)

# Also check if directly on a feature branch (non-worktree workflow)
if [ -z "$MISSING_BRANCH" ]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  case "$BRANCH" in
    main|master|""|HEAD) ;;
    *)
      COMMITS=$(git log master..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
      if [ "$COMMITS" != "0" ]; then
        BRANCH_SLUG=$(echo "$BRANCH" | tr '/' '-')
        if ! ls docs/changelogs/*"${BRANCH_SLUG}"* 1>/dev/null 2>&1; then
          MISSING_BRANCH="$BRANCH"
          MISSING_WT_PATH="."
        fi
      fi
      ;;
  esac
fi

# Block if a changelog is missing
if [ -n "$MISSING_BRANCH" ]; then
  BRANCH_SLUG=$(echo "$MISSING_BRANCH" | tr '/' '-')
  DATE=$(date +%Y-%m-%d)
  if [ "$MISSING_WT_PATH" = "." ]; then
    FILEPATH="docs/changelogs/${DATE}-${BRANCH_SLUG}.md"
  else
    FILEPATH="${MISSING_WT_PATH}/docs/changelogs/${DATE}-${BRANCH_SLUG}.md"
  fi
  cat <<EOF
{"decision":"block","reason":"CHANGELOG MISSING: Branch '${MISSING_BRANCH}' has commits but no changelog file. You MUST write ${FILEPATH} following the run-every-session skill's Phase 2 format, then commit it before ending the session."}
EOF
fi
