#!/usr/bin/env bash
# Usage: bash switch-model.sh [--list] [modelFilename]
#
# Hot-swaps the model koboldcpp is currently serving, without restarting the
# outer koboldcpp process or its port — the OpenCode/Goose session pointed at
# http://127.0.0.1:5001 keeps working unmodified, just waits a few seconds
# mid-swap. Uses koboldcpp's own built-in Admin API (needs --admin --admindir,
# which start.sh already passes), not a kill+relaunch done by this script.
#
#   bash switch-model.sh                  interactive picker (gum)
#   bash switch-model.sh --list           print available options, no swap
#   bash switch-model.sh qwen2.5-coder.gguf   swap directly, no picker
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
PORT=5001
BASE="http://127.0.0.1:$PORT"
GUM_BIN="$BIN_DIR/gum"
JQ_BIN="$BIN_DIR/jq"

if ! curl -s -o /dev/null "$BASE/v1/models"; then
  echo "koboldcpp isn't running on port $PORT. Start it first with: bash start.sh"
  exit 1
fi

OPTIONS_JSON="$(curl -s "$BASE/api/admin/list_options")"
mapfile -t OPTIONS < <(echo "$OPTIONS_JSON" | "$JQ_BIN" -r '.[]?' 2>/dev/null)

if [ "${#OPTIONS[@]}" -eq 0 ]; then
  echo "No admin options returned by koboldcpp. It needs to have been started"
  echo "with --admin --admindir (start.sh does this automatically) — if it's"
  echo "still running from before this feature was added, restart it via start.sh."
  exit 1
fi

if [ "${1:-}" = "--list" ]; then
  printf '%s\n' "${OPTIONS[@]}"
  exit 0
fi

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  TARGET="$("$GUM_BIN" choose "${OPTIONS[@]}" \
    --header "Switch koboldcpp to:" \
    --cursor.foreground 212 --selected.foreground 212)"
fi
if [ -z "$TARGET" ]; then
  echo "No model selected — nothing changed."
  exit 1
fi

MATCH=""
for o in "${OPTIONS[@]}"; do
  [ "$o" = "$TARGET" ] && MATCH="$o"
done
if [ -z "$MATCH" ]; then
  echo "'$TARGET' isn't one of the available options:"
  printf '  %s\n' "${OPTIONS[@]}"
  exit 1
fi

OLD_RESP="$(curl -s "$BASE/v1/models" 2>/dev/null || true)"
OLD_ID="$(echo "$OLD_RESP" | "$JQ_BIN" -r '.data[0].id // empty' 2>/dev/null || true)"

echo "Requesting swap to '$MATCH' ..."
SWAP_BODY="$("$JQ_BIN" -n --arg f "$MATCH" '{filename: $f}')"
SWAP_RESP="$(curl -s -X POST "$BASE/api/admin/reload_config" \
  -H "Content-Type: application/json" \
  -d "$SWAP_BODY")"

if [ "$(echo "$SWAP_RESP" | "$JQ_BIN" -r '.success // false')" != "true" ]; then
  echo "koboldcpp rejected the swap request: $SWAP_RESP"
  exit 1
fi

if [ "$MATCH" = "unload_model" ]; then
  echo -n "Waiting for koboldcpp to unload the model "
  for i in $(seq 1 30); do
    RESP="$(curl -s "$BASE/v1/models" 2>/dev/null || true)"
    CUR_ID="$(echo "$RESP" | "$JQ_BIN" -r '.data[0].id // empty' 2>/dev/null || true)"
    if [ -z "$CUR_ID" ]; then
      echo
      echo "Model unloaded."
      exit 0
    fi
    echo -n "."
    sleep 1
  done
  echo
  echo "Timed out waiting for the unload to complete — check koboldcpp.log"
  exit 1
fi

echo -n "Waiting for koboldcpp to come back up with the new model "
for i in $(seq 1 90); do
  RESP="$(curl -s "$BASE/v1/models" 2>/dev/null || true)"
  CUR_ID="$(echo "$RESP" | "$JQ_BIN" -r '.data[0].id // empty' 2>/dev/null || true)"
  if [ -n "$CUR_ID" ] && [ "$CUR_ID" != "$OLD_ID" ]; then
    echo
    echo "Now serving: $CUR_ID"
    exit 0
  fi
  echo -n "."
  sleep 1
done
echo
echo "Timed out waiting for koboldcpp to report a different model — check koboldcpp.log"
exit 1
