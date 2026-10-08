#!/usr/bin/env bash
set -euo pipefail

# Register the cliproxy models with t3code's Claude provider. t3code ships a
# fixed Claude model list and does not query the gateway like Claude CLI does,
# so only the claudeAgent customModels array in its settings.json is replaced;
# every other setting is left untouched. t3code only writes the claudeAgent
# instance once its settings are edited, so a default one is created if absent.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

MODELS_FILE="$DOTFILES_DIR/config/t3code/claude-custom-models.json"
SETTINGS_FILE="$HOME/.t3/userdata/settings.json"

say "🧵 t3code"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  say "⏭️  $SETTINGS_FILE not found; launch t3code once, then rerun."
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  say "⚠️  jq not found; skipping t3code custom models."
  exit 0
fi

updated="$(jq --slurpfile models "$MODELS_FILE" '
  .providerInstances.claudeAgent //= {
    driver: "claudeAgent",
    enabled: true,
    config: {binaryPath: "claude", homePath: "", launchArgs: "", autoCompactWindow: ""}
  }
  | .providerInstances.claudeAgent.config.customModels = $models[0]' \
  "$SETTINGS_FILE")"

if [[ "$(jq -S . "$SETTINGS_FILE")" == "$(jq -S . <<<"$updated")" ]]; then
  say "✅ t3code Claude custom models already up to date."
  exit 0
fi

if pgrep -f "T3 Code|t3 serve" >/dev/null 2>&1; then
  say "⚠️  t3code is running and may overwrite this change; restart it afterwards."
fi

mkdir -p "$BACKUP_DIR/t3code"
cp "$SETTINGS_FILE" "$BACKUP_DIR/t3code/settings.json"
say "📦 Backed up: $SETTINGS_FILE -> $BACKUP_DIR/t3code/"

printf '%s\n' "$updated" >"$SETTINGS_FILE"
say "✅ t3code Claude custom models updated."
