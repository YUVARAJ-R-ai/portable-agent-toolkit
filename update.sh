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
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  echo "Usage: bash update.sh <target_dir>" >&2
  echo "(<target_dir> must be an existing directory containing a portable agent install)" >&2
  exit 1
fi

JQ="$TARGET/bin/jq"
if [ ! -x "$JQ" ]; then
  JQ="$(find "$TARGET/bin" -maxdepth 1 -name "jq*" -type f 2>/dev/null | head -1)"
  [ -z "$JQ" ] && command -v jq >/dev/null 2>&1 && JQ="$(command -v jq)"
fi

GUM="$TARGET/bin/gum"
if [ ! -x "$GUM" ]; then
  GUM="$(find "$TARGET/bin" -maxdepth 1 -name "gum*" -type f 2>/dev/null | head -1)"
  [ -z "$GUM" ] && command -v gum >/dev/null 2>&1 && GUM="$(command -v gum)"
fi

if [ -f "$TARGET/.versions.json" ]; then
  MANIFEST="$(cat "$TARGET/.versions.json")"
else
  DETECTED_COMPONENTS="core"
  [ -d "$TARGET/dev" ] && DETECTED_COMPONENTS="$DETECTED_COMPONENTS dev"
  ([ -d "$TARGET/claude-code" ] || [ -f "$TARGET/bin/claude-code" ]) && DETECTED_COMPONENTS="$DETECTED_COMPONENTS claude-code"
  ([ -d "$TARGET/agy-cli" ] || [ -f "$TARGET/bin/agy" ]) && DETECTED_COMPONENTS="$DETECTED_COMPONENTS agy-cli"
  MANIFEST="$(cat <<EOF
{
  "installed_at": "unknown",
  "versions": {},
  "components": "$DETECTED_COMPONENTS",
  "models": []
}
EOF
)"
fi

COMPONENTS="$(echo "$MANIFEST" | "$JQ" -r '.components // empty')"
[ -z "$COMPONENTS" ] && COMPONENTS="core"

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
CHECK_ONE "koboldcpp" "LostRuins/koboldcpp" "$(echo "$MANIFEST" | "$JQ" -r '.versions.koboldcpp // empty')"
CHECK_ONE "opencode"  "anomalyco/opencode"  "$(echo "$MANIFEST" | "$JQ" -r '.versions.opencode // empty')"
CHECK_ONE "goose"     "block/goose"         "$(echo "$MANIFEST" | "$JQ" -r '.versions.goose // empty')"
CHECK_ONE "gum"       "charmbracelet/gum"   "$(echo "$MANIFEST" | "$JQ" -r '.versions.gum // empty')"
CHECK_ONE "jq"        "jqlang/jq"           "$(echo "$MANIFEST" | "$JQ" -r '.versions.jq // empty')"

if echo "$COMPONENTS" | grep -q "claude-code"; then
  CC_LATEST="$(curl -fsSL https://downloads.claude.ai/claude-code-releases/latest 2>/dev/null || true)"
  CC_INSTALLED="$("$TARGET/bin/claude-code" --version 2>/dev/null | head -1 || true)"
  if [ -n "$CC_LATEST" ]; then
    if [ -n "$CC_INSTALLED" ] && echo "$CC_INSTALLED" | grep -qF "$CC_LATEST"; then
      echo "  claude-code: up to date ($CC_INSTALLED)"
    else
      echo "  claude-code: UPDATE AVAILABLE  installed=[${CC_INSTALLED:-unknown}]  latest=[$CC_LATEST]"
      UPDATES_AVAILABLE=1
    fi
  fi
fi

if [ "$UPDATES_AVAILABLE" = "0" ]; then
  echo "Core components appear up to date."
fi

echo
CHOICES=("Runtime scripts & RAG corpus (refresh from toolkit repo)")
CHOICES+=("Core agent stack (koboldcpp, OpenCode, Goose, gum, jq)")
echo "$COMPONENTS" | grep -q "dev" && CHOICES+=("Dev environment (zig, rust, node, python)")
echo "$COMPONENTS" | grep -q "claude-code" && CHOICES+=("Claude Code")
echo "$COMPONENTS" | grep -q "agy-cli" && CHOICES+=("Agy CLI")

if [ -n "${UPDATE_COMPONENTS:-}" ]; then
  SELECTED="$UPDATE_COMPONENTS"
elif [ ! -t 0 ] || [ -z "$GUM" ] || [ ! -x "$GUM" ]; then
  SELECTED="Runtime scripts & RAG corpus (refresh from toolkit repo)"
else
  SELECTED="$("$GUM" choose --no-limit \
    --header "Select components to update/refresh (space to toggle, enter to confirm):" \
    --cursor.foreground 212 --selected.foreground 212 \
    "${CHOICES[@]}")"
fi

if [ -z "$SELECTED" ]; then
  echo "Nothing selected — no changes made."
  exit 0
fi

echo "$SELECTED" | grep -q "Runtime scripts" && {
  echo "== Refreshing runtime scripts, RAG corpus, and config =="
  cp -r "$SCRIPT_DIR/runtime/." "$TARGET/"
  mkdir -p "$TARGET/rag"
  cp -r "$SCRIPT_DIR/rag/." "$TARGET/rag/"
  if [ -d "$SCRIPT_DIR/goose-config" ]; then
    mkdir -p "$TARGET/goose-config"
    cp -r "$SCRIPT_DIR/goose-config/." "$TARGET/goose-config/"
  fi
  mkdir -p "$TARGET/config"
  cp "$SCRIPT_DIR/config/models.json" "$TARGET/config/models.json"
  chmod +x "$TARGET"/*.sh 2>/dev/null || true

  for b in koboldcpp goose gum jq; do
    if [ ! -f "$TARGET/bin/$b" ]; then
      cand="$(find "$TARGET/bin" -maxdepth 1 -name "${b}*" -type f 2>/dev/null | head -1)"
      if [ -n "$cand" ] && [ "$cand" != "$TARGET/bin/$b" ]; then
        cand_base="$(basename "$cand")"
        cat <<EOF > "$TARGET/bin/$b"
#!/usr/bin/env bash
exec "\$(dirname "\$0")/$cand_base" "\$@"
EOF
        chmod +x "$TARGET/bin/$b"
      fi
    fi
  done
}
echo "$SELECTED" | grep -q "Core agent stack" && bash "$SCRIPT_DIR/components/core-agent-stack.sh" "$TARGET"
echo "$SELECTED" | grep -q "Dev environment" && bash "$SCRIPT_DIR/components/dev-environment.sh" "$TARGET"
echo "$SELECTED" | grep -q "Claude Code" && bash "$SCRIPT_DIR/components/claude-code.sh" "$TARGET"
echo "$SELECTED" | grep -q "Agy CLI" && bash "$SCRIPT_DIR/components/agy-cli.sh" "$TARGET"

# refresh the manifest
"$JQ" -n \
  --arg installed_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg koboldcpp "$("$TARGET/bin/koboldcpp" --version 2>/dev/null | head -1)" \
  --arg opencode "$("$TARGET/bin/opencode" --version 2>/dev/null | head -1)" \
  --arg goose "$("$TARGET/bin/goose" --version 2>/dev/null | head -1)" \
  --arg gum "$("$TARGET/bin/gum" --version 2>/dev/null | head -1)" \
  --arg jq "$("$TARGET/bin/jq" --version 2>/dev/null | head -1)" \
  --arg agy "$([ -x "$TARGET/bin/agy" ] && "$TARGET/bin/agy" --version 2>/dev/null | head -1 || echo "")" \
  --arg components "$COMPONENTS" \
  --arg models "$(echo "$MANIFEST" | "$JQ" -r '.models')" \
  '{installed_at: $installed_at, versions: {koboldcpp: $koboldcpp, opencode: $opencode, goose: $goose, gum: $gum, jq: $jq, agy: $agy}, components: $components, models: $models}' \
  > "$TARGET/.versions.json"

echo "Update complete."
