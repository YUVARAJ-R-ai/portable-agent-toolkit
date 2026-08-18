#!/usr/bin/env bash
# Usage: bash models.sh <target_dir> <config/models.json path> <model_id> [model_id...]
# Downloads the selected GGUF model(s) from config/models.json's HuggingFace
# repo/file entries into <target_dir>/models/. No checksum is verified here
# (HuggingFace doesn't publish per-file SHA256 in a machine-readable spot the
# same way GitHub Releases do) -- the mitigation is pinning exact repo+file
# per model in config/models.json rather than resolving "latest"/"main"
# loosely, and each entry here was chosen from the model's official or a
# well-known community quantizer's repo, not an arbitrary upload.
set -e

TARGET="$1"; CONFIG="$2"; shift 2
MODEL_IDS=("$@")

if [ -z "$TARGET" ] || [ -z "$CONFIG" ] || [ "${#MODEL_IDS[@]}" -eq 0 ]; then
  echo "Usage: bash models.sh <target_dir> <config/models.json> <model_id> [model_id...]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

JQ_BIN="${JQ_BIN:-jq}"
mkdir -p "$TARGET/models"

for id in "${MODEL_IDS[@]}"; do
  entry="$("$JQ_BIN" -c --arg id "$id" '.models[] | select(.id == $id)' "$CONFIG")"
  if [ -z "$entry" ]; then
    echo "Unknown model id '$id' -- not found in $CONFIG" >&2
    exit 1
  fi

  repo="$(echo "$entry" | "$JQ_BIN" -r '.repo')"
  file="$(echo "$entry" | "$JQ_BIN" -r '.file')"
  size_gb="$(echo "$entry" | "$JQ_BIN" -r '.size_gb')"
  ram_warn="$(echo "$entry" | "$JQ_BIN" -r '.ram_warning_gb')"
  display="$(echo "$entry" | "$JQ_BIN" -r '.display_name')"

  dest="$TARGET/models/$id.gguf"
  if [ -f "$dest" ]; then
    echo "Already downloaded: $display ($dest) -- skipping."
    continue
  fi

  if [ "$ram_warn" != "0" ] && [ "$ram_warn" != "null" ]; then
    ram="$(total_ram_gb)"
    if [ "$ram" -gt 0 ] && [ "$ram" -lt "$ram_warn" ]; then
      echo "WARNING: $display needs ~${ram_warn}GB+ RAM to run comfortably;"
      echo "         this machine has ~${ram}GB. Downloading anyway (${size_gb}GB) --"
      echo "         it may run very slowly or fail to load. Ctrl+C to skip."
      sleep 3
    fi
  fi

  echo "Downloading $display (~${size_gb}GB) from $repo ..."
  url="https://huggingface.co/${repo}/resolve/main/${file}?download=true"
  download_verify "$url" "$dest"
  echo "  saved as models/$id.gguf"
done

echo "Model download step complete."
