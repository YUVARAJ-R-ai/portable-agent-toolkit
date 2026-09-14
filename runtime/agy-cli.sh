#!/usr/bin/env bash
# Usage: bash agy-cli.sh [agy args...]
# Launches the portable Agy (Antigravity) CLI from this install.
# Configures the home directory environment variable so Agy saves its configs and OAuth tokens locally.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGY_BIN="$SCRIPT_DIR/bin/agy"
AGY_DIR="$SCRIPT_DIR/agy-cli"

if [ ! -x "$AGY_BIN" ]; then
  echo "Agy CLI isn't installed. Run install.sh with the agy-cli component."
  exit 1
fi

export HOME="$AGY_DIR/home"
export USERPROFILE="$AGY_DIR/home"

WORKSPACE_DIR="$AGY_DIR/workspace"
AGY_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --workspace)
      WORKSPACE_DIR="$2"
      shift 2
      ;;
    *)
      AGY_ARGS+=("$1")
      shift
      ;;
  esac
done

mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# Execute Agy with all passed arguments
"$AGY_BIN" "${AGY_ARGS[@]}"
