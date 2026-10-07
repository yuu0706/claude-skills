#!/usr/bin/env bash
# PreToolUse(Bash) hook. Runs gitleaks before `git commit` and blocks the commit when a secret is found.
# Input: hook JSON on stdin. Exit 2 blocks the tool call; stderr is shown to Claude.
set -u

input=$(cat)
command=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null) || exit 0
cwd=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("cwd",""))' 2>/dev/null)

# Only `git commit` (including `git -C <dir> commit`) is checked.
printf '%s' "$command" | grep -Eq '(^|[;&|[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+commit([[:space:]]|$)' || exit 0

repo_dir=$cwd
c_dir=$(printf '%s' "$command" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+([^[:space:]]+)[[:space:]]+commit.*/\1/p' | head -n1)
cd_dir=$(printf '%s' "$command" | sed -nE 's/^[[:space:]]*cd[[:space:]]+([^;&|[:space:]]+).*/\1/p' | head -n1)
[ -n "$cd_dir" ] && repo_dir=$cd_dir
[ -n "$c_dir" ] && repo_dir=$c_dir
repo_dir=${repo_dir/#\~/$HOME}
[ -n "$repo_dir" ] && cd "$repo_dir" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

if ! command -v gitleaks >/dev/null 2>&1; then
  printf '{"systemMessage":"gitleaks is not installed; the pre-commit secret scan was skipped. Run: brew install gitleaks"}\n'
  exit 0
fi

# `commit -a` / `--all` stages tracked changes at commit time, so scan the working-tree diff instead.
if printf '%s' "$command" | grep -Eq 'commit([[:space:]]+[^[:space:]]+)*[[:space:]]+(-[a-zA-Z]*a[a-zA-Z]*|--all)([[:space:]]|$)'; then
  # A repository without commits has no HEAD; compare against the empty tree.
  base=$(git rev-parse -q --verify HEAD || git hash-object -t tree /dev/null)
  report=$(git diff "$base" | gitleaks stdin --no-banner --redact 2>&1)
else
  report=$(gitleaks git --staged --no-banner --redact . 2>&1 || true)
  if printf '%s' "$report" | grep -q 'unknown command'; then
    report=$(gitleaks protect --staged --no-banner --redact 2>&1)
  fi
fi

if printf '%s' "$report" | grep -Eq 'leaks found: [1-9]'; then
  {
    echo "gitleaks found secrets in the changes to be committed. The commit was blocked."
    echo "Follow Skill security-rules section 6 and Skill commit-guard section 6. Do not bypass this hook."
    echo "$report"
  } >&2
  exit 2
fi
exit 0
