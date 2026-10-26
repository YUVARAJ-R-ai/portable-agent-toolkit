#!/usr/bin/env bash
# Usage: bash claude-code.sh [--skip-permissions] [-r|--resume [id]] [-c|--continue] [claude args...]
# Launches the real, cloud-hosted Claude Code CLI from this install, pre-
# authenticated via a long-lived OAuth token you generate once. Unlike
# start.sh/chat.sh (which talk to the local koboldcpp server), this needs a
# real internet connection and uses your actual Anthropic account/billing.
#
# --skip-permissions (or -y): shorthand for --dangerously-skip-permissions.
# Every tool call runs with NO confirmation, including destructive shell
# commands and file deletions — not the default on purpose. Opt in per
# session when you actually need it.
#
# -r/--resume [sessionId] and -c/--continue: native Claude Code flags,
# forwarded through unchanged. Session history lives under
# claude-code/config/ here, keyed by this workspace's absolute path — which
# differs per host/mount point, so a session started elsewhere may not show
# up under --continue on a different machine. Use plain --resume (no ID) for
# the interactive picker if history looks empty.
# Windows (Git Bash / MSYS / Cygwin): the Linux binaries in bin/ can't run here, so hand off to the PowerShell twin.
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*)
  a=(); for x in "$@"; do case "$x" in --skip-permissions|-y) a+=(-SkipPermissions) ;; *) a+=("$x") ;; esac; done
  exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$(dirname "${BASH_SOURCE[0]}")")\\claude-code.ps1" "${a[@]}" ;;
esac
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_BIN="$SCRIPT_DIR/bin/claude-code"
CC_DIR="$SCRIPT_DIR/claude-code"
TOKEN_FILE="$CC_DIR/token.txt"

if [ ! -x "$CLAUDE_BIN" ]; then
  echo "Claude Code isn't installed. Run install.sh with the Claude Code"
  echo "component selected first."
  exit 1
fi

if [ ! -s "$TOKEN_FILE" ]; then
  cat <<EOF
No auth token found at:
  $TOKEN_FILE

One-time setup (do this once, anywhere you have a browser):
  1. Run:  "$CLAUDE_BIN" setup-token
  2. Approve access in the browser that opens.
  3. Copy the token it prints and save it as the ONLY content of:
       $TOKEN_FILE
     e.g.:  echo 'sk-ant-oat01-...' > "$TOKEN_FILE"

This token is a plaintext credential tied to your real Claude account and
billing (Pro/Max/Team/Enterprise) — see docs/claude-code.md for the
security tradeoff and how to revoke it if this install is ever lost/shared.
EOF
  exit 1
fi

export CLAUDE_CODE_OAUTH_TOKEN="$(tr -d '[:space:]' < "$TOKEN_FILE")"
export CLAUDE_CONFIG_DIR="$CC_DIR/config"

CLAUDE_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --skip-permissions|-y)
      echo "WARNING: launching with --dangerously-skip-permissions — every tool call runs with NO confirmation." >&2
      CLAUDE_ARGS+=("--dangerously-skip-permissions")
      ;;
    *)
      CLAUDE_ARGS+=("$arg")
      ;;
  esac
done

mkdir -p "$CC_DIR/workspace"
cd "$CC_DIR/workspace"
"$CLAUDE_BIN" "${CLAUDE_ARGS[@]}"
