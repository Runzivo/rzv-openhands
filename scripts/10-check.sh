#!/usr/bin/env bash
# Static checks for the skills in this repository. No network, no dependencies beyond bash and awk.
set -euo pipefail
cd "$(dirname "$0")/.."
status=0
err() { printf 'ERROR: %s\n' "$*" >&2; status=1; }

for skill in skills/*/; do
  dir=${skill%/}; name=${dir#skills/}; file=$dir/SKILL.md
  [ -f "$file" ] || { err "$dir has no SKILL.md"; continue; }
  [ -f "$dir/README.md" ] || err "$dir has no README.md"
  [ "$(head -n 1 "$file")" = "---" ] || { err "$file must start with --- frontmatter"; continue; }
  front=$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$file")
  fm_name=$(printf '%s\n' "$front" | awk -F': ' '$1 == "name" { print $2 }')
  desc=$(printf '%s\n' "$front" | awk -F': ' '$1 == "description" { sub(/^description: /, ""); print }')
  [ "$fm_name" = "$name" ] || err "$file: name '$fm_name' must match directory '$name'"
  [[ "$fm_name" =~ ^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$ ]] || err "$file: name must be lowercase letters, digits and hyphens"
  [ -n "$desc" ] || err "$file: description is required"
  [ "${#desc}" -le 1024 ] || err "$file: description is longer than 1024 characters"
  printf '%s\n' "$front" | grep -q '^triggers:$' || err "$file: triggers: list is missing"
  # Every references/... path the skill mentions must exist.
  while IFS= read -r ref; do
    [ -f "$dir/$ref" ] || err "$file mentions $ref, which does not exist"
  done < <(grep -o 'references/[A-Za-z0-9._-]*' "$file" | sort -u)
done

while IFS= read -r md; do
  lines=$(wc -l <"$md" | tr -d ' ')
  [ "$lines" -le 60 ] || err "$md has $lines lines; keep Markdown files to 60"
  if grep -q $'\xe2\x80\x94' "$md"; then err "$md contains an em dash; use a plain hyphen"; fi
done < <(find . -name '*.md' -not -path './.git/*' | sort)

[ "$status" -eq 0 ] && echo "checks passed"
exit "$status"
