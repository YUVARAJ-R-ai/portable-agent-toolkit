#!/usr/bin/env bash
# Usage: bash claude-code.sh <target_dir>
# Downloads the real, standalone Claude Code CLI binary (no Node/npm needed
# at runtime) into <target_dir>/bin/claude-code, checksum-verified against
# Anthropic's own published manifest.json. This is OPTIONAL and separate from
# the rest of the AI-agent stack: it needs a real internet connection and the
# user's own Anthropic subscription (Pro/Max/Team/Enterprise) -- there is
# nothing to auto-provision here, the user runs `claude setup-token`
# themselves after install (see docs/claude-code.md and runtime/claude-code.sh).
set -e

TARGET="$1"
if [ -z "$TARGET" ]; then
  echo "Usage: bash claude-code.sh <target_dir>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

OS="$(detect_os)"
ARCH="$(detect_arch)"
case "$OS-$ARCH" in
  linux-x64)   PLATFORM="linux-x64" ;;
  linux-arm64) PLATFORM="linux-arm64" ;;
  mac-arm64)   PLATFORM="darwin-arm64" ;;
  mac-x64)     PLATFORM="darwin-x64" ;;
  *) echo "No Claude Code build for $OS-$ARCH" >&2; exit 1 ;;
esac

echo "== Claude Code CLI =="
VERSION="$(curl -fsSL https://downloads.claude.ai/claude-code-releases/latest)"
echo "  version $VERSION"

MANIFEST="$(curl -fsSL "https://downloads.claude.ai/claude-code-releases/${VERSION}/manifest.json")"
JQ="$TARGET/bin/jq"
if [ -x "$JQ" ]; then
  SHA="$("$JQ" -r --arg p "$PLATFORM" '.platforms[$p].checksum' <<<"$MANIFEST")"
else
  # jq not installed yet (this component can run standalone) -- fall back to
  # a plain grep, good enough for this one lookup. Verified against the real
  # manifest.json structure: {"platforms": {"<platform>": {"checksum": "..."}}}.
  SHA="$(echo "$MANIFEST" | grep -A3 "\"$PLATFORM\"" | grep -o '"checksum": *"[a-f0-9]*"' | grep -o '[a-f0-9]\{64\}')"
fi

mkdir -p "$TARGET/bin" "$TARGET/claude-code/config" "$TARGET/claude-code/workspace"
BIN_URL="https://downloads.claude.ai/claude-code-releases/${VERSION}/${PLATFORM}/claude"
download_verify "$BIN_URL" "$TARGET/bin/claude-code" "$SHA"
chmod +x "$TARGET/bin/claude-code"

"$TARGET/bin/claude-code" --version >/dev/null 2>&1 && echo "  claude-code: OK" || echo "  claude-code: FAILED to run --version" >&2

echo
echo "Claude Code binary installed. One-time step YOU must do (can't be scripted --"
echo "it's a real OAuth login against your own account):"
echo "  1. Run: $TARGET/bin/claude-code setup-token"
echo "  2. Approve access in the browser tab that opens."
echo "  3. Save the printed token as the ONLY content of:"
echo "       $TARGET/claude-code/token.txt"
echo "See docs/claude-code.md for the full explanation and security tradeoffs."
