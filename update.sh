#!/usr/bin/env bash
# Usage: bash update.sh <target_dir>
# Checks the currently-installed versions (recorded in <target_dir>/.versions.json
# by install.sh) against each project's latest GitHub release, shows what's
# outdated, and lets you pick which components to refresh. Re-runs the same
# component script that originally installed it -- there's no separate
# "patch" mechanism, each component script always installs the current
# latest release of everything it's responsible for.
#
# Model weights are NOT covered here -- they don't get updated in place.
# To add a different model later, run install.sh's model step again (or
# `bash components/models.sh <target> config/models.json <id>` directly).
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

TARGET="$1"
if [ -z "$TARGET" ] || [ ! -f "$TARGET/.versions.json" ]; then
  echo "Usage: bash update.sh <target_dir>" >&2
  echo "(<target_dir> must be a directory previously set up by install.sh --" >&2
  echo " no .versions.json manifest found there)" >&2
  exit 1
fi

JQ="$TARGET/bin/jq"
GUM="$TARGET/bin/gum"
MANIFEST="$(cat "$TARGET/.versions.json")"
COMPONENTS="$(echo "$MANIFEST" | "$JQ" -r '.components')"

echo "Checking for updates ..."

CHECK_ONE() {
  # CHECK_ONE <label> <repo> <installed_version_string>
  local label="$1" repo="$2" installed="$3"
  local latest
  latest="$(latest_github_release "$repo")"
  # installed version strings look like "1.119" / "v1.46.0 (goose)" etc --
  # just check whether the latest tag (stripped of a leading v) appears
  # anywhere in the installed string, good enough to flag "different".
  local latest_stripped="${latest#v}"
  if [ -z "$installed" ]; then
    echo "  $label: not installed"
  elif echo "$installed" | grep -qF "$latest_stripped"; then
    echo "  $label: up to date ($installed)"
  else
    echo "  $label: UPDATE AVAILABLE  installed=[$installed]  latest=[$latest]"
    UPDATES_AVAILABLE=1
  fi
}

UPDATES_AVAILABLE=0
CHECK_ONE "koboldcpp" "LostRuins/koboldcpp" "$(echo "$MANIFEST" | "$JQ" -r '.versions.koboldcpp')"
CHECK_ONE "opencode"  "sst/opencode"        "$(echo "$MANIFEST" | "$JQ" -r '.versions.opencode')"
CHECK_ONE "goose"     "block/goose"         "$(echo "$MANIFEST" | "$JQ" -r '.versions.goose')"
CHECK_ONE "gum"       "charmbracelet/gum"   "$(echo "$MANIFEST" | "$JQ" -r '.versions.gum')"
CHECK_ONE "jq"        "jqlang/jq"           "$(echo "$MANIFEST" | "$JQ" -r '.versions.jq')"

if [ "$UPDATES_AVAILABLE" = "0" ]; then
  echo "Everything is up to date."
  exit 0
fi

echo
CHOICES=("Core agent stack (koboldcpp, OpenCode, Goose, gum, jq)")
echo "$COMPONENTS" | grep -q "dev" && CHOICES+=("Dev environment (zig, rust, node, python)")
echo "$COMPONENTS" | grep -q "claude-code" && CHOICES+=("Claude Code")

SELECTED="$("$GUM" choose --no-limit \
  --header "Select components to update:" \
  --cursor.foreground 212 --selected.foreground 212 \
  "${CHOICES[@]}")"

if [ -z "$SELECTED" ]; then
  echo "Nothing selected — no changes made."
  exit 0
fi

echo "$SELECTED" | grep -q "Core agent stack" && bash "$SCRIPT_DIR/components/core-agent-stack.sh" "$TARGET"
echo "$SELECTED" | grep -q "Dev environment" && bash "$SCRIPT_DIR/components/dev-environment.sh" "$TARGET"
echo "$SELECTED" | grep -q "Claude Code" && bash "$SCRIPT_DIR/components/claude-code.sh" "$TARGET"

# refresh the manifest
"$JQ" -n \
  --arg installed_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg koboldcpp "$("$TARGET/bin/koboldcpp" --version 2>/dev/null | head -1)" \
  --arg opencode "$("$TARGET/bin/opencode" --version 2>/dev/null | head -1)" \
  --arg goose "$("$TARGET/bin/goose" --version 2>/dev/null | head -1)" \
  --arg gum "$("$TARGET/bin/gum" --version 2>/dev/null | head -1)" \
  --arg jq "$("$TARGET/bin/jq" --version 2>/dev/null | head -1)" \
  --arg components "$COMPONENTS" \
  --arg models "$(echo "$MANIFEST" | "$JQ" -r '.models')" \
  '{installed_at: $installed_at, versions: {koboldcpp: $koboldcpp, opencode: $opencode, goose: $goose, gum: $gum, jq: $jq}, components: $components, models: $models}' \
  > "$TARGET/.versions.json"

echo "Update complete."
