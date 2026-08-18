#!/usr/bin/env bash
# Usage: bash install.sh [--target <dir>] [--components core,dev,claude-code]
#                         [--models qwen2.5-coder,nanbeige] [--yes]
#
# Interactive TUI installer for the Portable Agent Toolkit — a local, fully
# offline AI coding-agent stack (koboldcpp + OpenCode + Goose + a tool-call
# RAG system for DAA algorithms), an optional portable dev environment
# (C/C++, Rust, Node.js/React, Python — no host toolchain needed), and an
# optional real Claude Code CLI launcher.
#
# Non-interactive / scripted use: pass --target, --components, and --models
# to skip every prompt (see docs/install.md). Anything left unspecified
# falls back to an interactive gum prompt.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

TARGET=""
COMPONENTS=""
MODELS=""
ASSUME_YES=0

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --components) COMPONENTS="$2"; shift 2 ;;
    --models) MODELS="$2"; shift 2 ;;
    --yes) ASSUME_YES=1; shift ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

OS="$(detect_os)"
if [ "$OS" = "unknown" ]; then
  echo "Unsupported OS. This installer supports Linux and macOS (use install.ps1 on Windows)." >&2
  exit 1
fi

if [ -z "$TARGET" ]; then
  read -r -p "Install directory [$(pwd)/portable-agent]: " TARGET
  TARGET="${TARGET:-$(pwd)/portable-agent}"
fi
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
echo "Installing into: $TARGET"

GUM_BIN="$(ensure_gum "$TARGET")"
JQ_BIN="$(ensure_jq "$TARGET")"

# --- Component selection ----------------------------------------------------
if [ -z "$COMPONENTS" ]; then
  "$GUM_BIN" style --border rounded --padding "0 2" --margin "1 0" \
    --border-foreground 212 --foreground 212 \
    "Portable Agent Toolkit — Installer"
  echo "Core AI-agent stack (koboldcpp + OpenCode + Goose + RAG) is always installed."
  SELECTED="$("$GUM_BIN" choose --no-limit \
    --header "Select optional components (space to toggle, enter to confirm):" \
    --cursor.foreground 212 --selected.foreground 212 \
    "Dev environment (C/C++, Rust, Node.js/React, Python)" \
    "Claude Code (needs your own Anthropic subscription)")"
  COMPONENTS="core"
  echo "$SELECTED" | grep -q "Dev environment" && COMPONENTS="$COMPONENTS,dev"
  echo "$SELECTED" | grep -q "Claude Code" && COMPONENTS="$COMPONENTS,claude-code"
fi
echo "Components: $COMPONENTS"

# --- Model selection ---------------------------------------------------------
if [ -z "$MODELS" ]; then
  MODEL_LABELS=()
  MODEL_IDS=()
  DEFAULT_LABEL=""
  while IFS= read -r m; do
    id="$(echo "$m" | "$JQ_BIN" -r '.id')"
    display="$(echo "$m" | "$JQ_BIN" -r '.display_name')"
    size="$(echo "$m" | "$JQ_BIN" -r '.size_gb')"
    label="$display (~${size}GB)"
    MODEL_LABELS+=("$label")
    MODEL_IDS+=("$id")
    default_sel="$(echo "$m" | "$JQ_BIN" -r '.default_selected')"
    [ "$default_sel" = "true" ] && DEFAULT_LABEL="$label"
  done < <("$JQ_BIN" -c '.models[]' "$SCRIPT_DIR/config/models.json")

  RAM="$(total_ram_gb)"
  echo "Detected system RAM: ~${RAM}GB"
  SELECTED_MODELS="$("$GUM_BIN" choose --no-limit \
    --header "Select model(s) to download (space to toggle, enter to confirm):" \
    --selected "$DEFAULT_LABEL" \
    --cursor.foreground 212 --selected.foreground 212 \
    "${MODEL_LABELS[@]}")"

  MODELS=""
  for i in "${!MODEL_LABELS[@]}"; do
    if echo "$SELECTED_MODELS" | grep -qF "${MODEL_LABELS[$i]}"; then
      MODELS="${MODELS:+$MODELS,}${MODEL_IDS[$i]}"
    fi
  done
fi
echo "Models: ${MODELS:-none}"

# --- Run components -----------------------------------------------------------
bash "$SCRIPT_DIR/components/core-agent-stack.sh" "$TARGET"

if [ -n "$MODELS" ]; then
  IFS=',' read -ra MODEL_ARR <<< "$MODELS"
  bash "$SCRIPT_DIR/components/models.sh" "$TARGET" "$SCRIPT_DIR/config/models.json" "${MODEL_ARR[@]}"
fi

echo "$COMPONENTS" | grep -q "dev" && bash "$SCRIPT_DIR/components/dev-environment.sh" "$TARGET"
echo "$COMPONENTS" | grep -q "claude-code" && bash "$SCRIPT_DIR/components/claude-code.sh" "$TARGET"

# --- Deploy the runtime scripts + RAG corpus + config into $TARGET ----------
echo "== Deploying runtime scripts, RAG corpus, and config =="
cp -r "$SCRIPT_DIR/runtime/." "$TARGET/"
cp -r "$SCRIPT_DIR/rag" "$TARGET/rag"
mkdir -p "$TARGET/config"
cp "$SCRIPT_DIR/config/models.json" "$TARGET/config/models.json"
chmod +x "$TARGET"/*.sh 2>/dev/null || true

# --- Write the version manifest (update.sh reads this) -----------------------
"$TARGET/bin/jq" -n \
  --arg installed_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg koboldcpp "$("$TARGET/bin/koboldcpp" --version 2>/dev/null | head -1)" \
  --arg opencode "$("$TARGET/bin/opencode" --version 2>/dev/null | head -1)" \
  --arg goose "$("$TARGET/bin/goose" --version 2>/dev/null | head -1)" \
  --arg gum "$("$TARGET/bin/gum" --version 2>/dev/null | head -1)" \
  --arg jq "$("$TARGET/bin/jq" --version 2>/dev/null | head -1)" \
  --arg components "$COMPONENTS" \
  --arg models "$MODELS" \
  '{installed_at: $installed_at, versions: {koboldcpp: $koboldcpp, opencode: $opencode, goose: $goose, gum: $gum, jq: $jq}, components: $components, models: $models}' \
  > "$TARGET/.versions.json"

"$GUM_BIN" style --border rounded --padding "0 2" --margin "1 0" \
  --border-foreground 212 --foreground 212 \
  "Install complete!"
echo
echo "Installed into: $TARGET"
echo
echo "Run it:"
echo "  cd '$TARGET'"
echo "  bash start.sh                 # koboldcpp + pick a model + pick OpenCode/Goose"
echo "  bash chat.sh                  # plain terminal chat, no orchestrator"
echo "$COMPONENTS" | grep -q "dev" && echo "  bash dev.sh                    # enter the portable C/C++/Rust/Node/Python shell"
echo "$COMPONENTS" | grep -q "claude-code" && echo "  bash claude-code.sh            # real Claude Code CLI (needs 'claude-code setup-token' once)"
echo
echo "To update components later: bash update.sh (from wherever you keep this repo checked out)"
