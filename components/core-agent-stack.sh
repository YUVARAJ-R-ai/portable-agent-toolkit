#!/usr/bin/env bash
# Usage: bash core-agent-stack.sh <target_dir>
# Downloads koboldcpp, OpenCode, Goose, gum, and jq for the CURRENT platform
# into <target_dir>/bin/. Version resolved dynamically from each project's
# GitHub "latest release" -- the same source update.sh checks against later,
# so there's one source of truth for "what's the current version" everywhere
# in this project, not a hardcoded version number that goes stale.
set -e

TARGET="$1"
if [ -z "$TARGET" ]; then
  echo "Usage: bash core-agent-stack.sh <target_dir>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

OS="$(detect_os)"
ARCH="$(detect_arch)"
mkdir -p "$TARGET/bin"

echo "== koboldcpp =="
case "$OS-$ARCH" in
  linux-x64)  KOBOLD_ASSET="koboldcpp-linux-x64-nocuda" ;;
  mac-arm64)  KOBOLD_ASSET="koboldcpp-mac-arm64" ;;
  *) echo "No koboldcpp build for $OS-$ARCH" >&2; exit 1 ;;
esac
KOBOLD_URL="$(gh_asset_url "LostRuins/koboldcpp" "$KOBOLD_ASSET")"
[ -z "$KOBOLD_URL" ] && { echo "Could not resolve koboldcpp download URL" >&2; exit 1; }
download_verify "$KOBOLD_URL" "$TARGET/bin/koboldcpp"
chmod +x "$TARGET/bin/koboldcpp"

echo "== OpenCode =="
case "$OS-$ARCH" in
  linux-x64)  OC_ASSET="opencode-linux-x64.tar.gz" ;;
  mac-arm64)  OC_ASSET="opencode-darwin-arm64.zip" ;;
  *) echo "No OpenCode build for $OS-$ARCH" >&2; exit 1 ;;
esac
OC_URL="$(gh_asset_url "sst/opencode" "$OC_ASSET")"
[ -z "$OC_URL" ] && { echo "Could not resolve OpenCode download URL" >&2; exit 1; }
OC_TMP="$(mktemp -d)"
download_verify "$OC_URL" "$OC_TMP/$OC_ASSET"
case "$OC_ASSET" in
  *.tar.gz) tar -xzf "$OC_TMP/$OC_ASSET" -C "$OC_TMP" ;;
  *.zip)    unzip -q "$OC_TMP/$OC_ASSET" -d "$OC_TMP" ;;
esac
find "$OC_TMP" -maxdepth 2 -type f -name "opencode" -exec cp {} "$TARGET/bin/opencode" \;
chmod +x "$TARGET/bin/opencode"
rm -rf "$OC_TMP"

echo "== Goose =="
case "$OS-$ARCH" in
  linux-x64)  GOOSE_ASSET="goose-x86_64-unknown-linux-gnu.tar.gz" ;;
  mac-arm64)  GOOSE_ASSET="goose-aarch64-apple-darwin.tar.gz" ;;
  *) echo "No Goose build for $OS-$ARCH" >&2; exit 1 ;;
esac
GOOSE_URL="$(gh_asset_url "block/goose" "$GOOSE_ASSET")"
[ -z "$GOOSE_URL" ] && { echo "Could not resolve Goose download URL" >&2; exit 1; }
GOOSE_TMP="$(mktemp -d)"
download_verify "$GOOSE_URL" "$GOOSE_TMP/$GOOSE_ASSET"
tar -xzf "$GOOSE_TMP/$GOOSE_ASSET" -C "$GOOSE_TMP"
find "$GOOSE_TMP" -maxdepth 2 -type f -name "goose" -exec cp {} "$TARGET/bin/goose" \;
chmod +x "$TARGET/bin/goose"
rm -rf "$GOOSE_TMP"

echo "== gum =="
GUM_BIN="$(ensure_gum "$TARGET")"
[ "$GUM_BIN" != "$TARGET/bin/gum" ] && cp "$GUM_BIN" "$TARGET/bin/gum"

echo "== jq (checksum-verified) =="
case "$OS-$ARCH" in
  linux-x64)  JQ_ASSET="jq-linux-amd64" ;;
  linux-arm64) JQ_ASSET="jq-linux-arm64" ;;
  mac-arm64)  JQ_ASSET="jq-macos-arm64" ;;
  mac-x64)    JQ_ASSET="jq-macos-amd64" ;;
  *) echo "No jq build for $OS-$ARCH" >&2; exit 1 ;;
esac
JQ_URL="$(gh_asset_url "jqlang/jq" "$JQ_ASSET")"
SHA_URL="$(gh_asset_url "jqlang/jq" "sha256sum.txt")"
JQ_SHA="$(curl -fsSL "$SHA_URL" | grep "$JQ_ASSET\$" | awk '{print $1}')"
download_verify "$JQ_URL" "$TARGET/bin/jq" "$JQ_SHA"
chmod +x "$TARGET/bin/jq"

echo "Core agent stack installed into $TARGET/bin/"
echo "  koboldcpp, opencode, goose, gum, jq -- all verified executable below."
for b in koboldcpp opencode goose gum jq; do
  "$TARGET/bin/$b" --version >/dev/null 2>&1 && echo "  $b: OK" || echo "  $b: FAILED to run --version" >&2
done
