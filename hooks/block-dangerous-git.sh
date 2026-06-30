#!/usr/bin/env bash
# Git guardrails hook for Claude Code.
# Blocks destructive git commands before they execute.
# Install: copy to ~/.claude/hooks/ and add PreToolUse hook in ~/.claude/settings.json

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

DANGEROUS_PATTERNS=(
  "git push"
  "push --force"
  "git reset --hard"
  "reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' — operación git destructiva bloqueada. Confirmá con el usuario antes de ejecutar esto manualmente." >&2
    exit 2
  fi
done

exit 0
