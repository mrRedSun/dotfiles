#!/usr/bin/env bash
set -euo pipefail

# Link repo-managed personal AI skills into the locations discovered by
# Claude Code, Codex, and OpenCode. Codex and OpenCode share the open-standard
# ~/.agents/skills location, so a single link set serves both tools without
# creating duplicate skill definitions in OpenCode.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

SKILLS_DIR="$DOTFILES_DIR/skills"

SKILL_TARGET_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.agents/skills"
)
SKILL_TARGET_NAMES=(
  "Claude Code"
  "Codex and OpenCode"
)
SKILL_TARGET_BACKUP_KEYS=(
  "claude"
  "agents"
)

say() {
  printf '%s\n' "$1"
}

backup_target() {
  local target_path="$1"
  local backup_key="$2"
  local skill_name="$3"
  local backup_path="$BACKUP_DIR/ai-skills/$backup_key/$skill_name"
  local backup_index=2

  while [[ -e "$backup_path" || -L "$backup_path" ]]; do
    backup_path="$BACKUP_DIR/ai-skills/$backup_key/$skill_name-$backup_index"
    ((backup_index += 1))
  done

  mkdir -p "$(dirname "$backup_path")"
  mv "$target_path" "$backup_path"
  say "📦 Backed up: $target_path -> $backup_path"
}

link_skill() {
  local source_path="$1"
  local target_path="$2"
  local backup_key="$3"
  local skill_name="$4"

  if [[ -L "$target_path" ]] && [[ "$(readlink "$target_path")" == "$source_path" ]]; then
    say "✅ Already linked: $target_path"
    return 0
  fi

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    backup_target "$target_path" "$backup_key" "$skill_name"
  fi

  ln -s "$source_path" "$target_path"
  say "🔗 Linked: $target_path -> $source_path"
}

backup_stale_links() {
  local target_dir="$1"
  local backup_key="$2"
  local target_path
  local source_path
  local skill_name

  for target_path in "$target_dir"/*; do
    if [[ ! -L "$target_path" ]]; then
      continue
    fi

    source_path="$(readlink "$target_path")"
    if [[ "$source_path" == "$SKILLS_DIR"/* ]] && [[ ! -e "$source_path" ]]; then
      skill_name="$(basename "$target_path")"
      backup_target "$target_path" "$backup_key" "$skill_name"
      say "🧹 Removed stale repo-managed skill link: $target_path"
    fi
  done
}

if [[ ! -d "$SKILLS_DIR" ]]; then
  say "❌ Missing skills directory: $SKILLS_DIR" >&2
  exit 1
fi

shopt -s nullglob
skill_files=("$SKILLS_DIR"/*/SKILL.md)

if [[ "${#skill_files[@]}" -eq 0 ]]; then
  say "❌ No skills found in: $SKILLS_DIR" >&2
  exit 1
fi

say "🧠 Linking ${#skill_files[@]} personal AI skills..."

for i in "${!SKILL_TARGET_DIRS[@]}"; do
  target_dir="${SKILL_TARGET_DIRS[$i]}"
  target_name="${SKILL_TARGET_NAMES[$i]}"
  backup_key="${SKILL_TARGET_BACKUP_KEYS[$i]}"

  say "🤖 $target_name: $target_dir"
  mkdir -p "$target_dir"
  backup_stale_links "$target_dir" "$backup_key"

  for skill_file in "${skill_files[@]}"; do
    source_path="$(dirname "$skill_file")"
    skill_name="$(basename "$source_path")"
    link_skill "$source_path" "$target_dir/$skill_name" "$backup_key" "$skill_name"
  done
done

say "✅ Personal AI skills linked for Claude Code, Codex, and OpenCode."
