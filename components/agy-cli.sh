#!/usr/bin/env bash
# Usage: bash agy-cli.sh <target_dir>
# Setup the portable Agy (Antigravity) CLI into <target_dir>/bin/agy.
# Since Agy is generally an installed tool, it tries to copy it from the host environment.
# Sets up the isolated workspace and config directory for Agy to use persistent OAuth tokens locally.
set -e

TARGET="$1"
if [ -z "$TARGET" ]; then
  echo "Usage: bash agy-cli.sh <target_dir>" >&2
  exit 1
fi

echo "== Agy CLI =="

mkdir -p "$TARGET/bin" "$TARGET/agy-cli/home" "$TARGET/agy-cli/workspace"

if command -v agy >/dev/null 2>&1; then
  AGY_PATH="$(command -v agy)"
  # Use -L to resolve symlinks in case it's managed by a package manager (like NixOS)
  cp -L "$AGY_PATH" "$TARGET/bin/agy"
  chmod +x "$TARGET/bin/agy"
  echo "  agy-cli: Copied from host ($AGY_PATH)"
  "$TARGET/bin/agy" --help >/dev/null 2>&1 && echo "  agy-cli: OK" || echo "  agy-cli: WARNING: binary copied but requires host dynamic libraries." >&2
else
  echo "  agy-cli: WARNING: 'agy' executable not found on host system." >&2
  echo "  To use Agy CLI portably, place an 'agy' binary into $TARGET/bin/agy." >&2
fi

echo
echo "Agy CLI binary installed. One-time setup:"
echo "  1. Run: $TARGET/agy-cli.sh"
echo "  2. Follow the interactive setup/OAuth login."
echo "Your settings and OAuth tokens will be saved to the portable directory."
