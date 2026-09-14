#!/usr/bin/env bash
# Usage: bash chat.sh [model]
# Plain terminal chat with the local model — no browser, no opencode/goose,
# no agentic tool-use, just back-and-forth text. Much faster than the
# orchestrators since there's no multi-thousand-token tool-schema overhead
# per turn.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
LOG="$SCRIPT_DIR/koboldcpp.log"
PORT=5001
JQ_BIN="$BIN_DIR/jq"

PHYSICAL_CORES="$(awk -F: '/cpu cores/{print $2; exit}' /proc/cpuinfo 2>/dev/null | tr -d ' ')"
[ -z "$PHYSICAL_CORES" ] && PHYSICAL_CORES="$(sysctl -n hw.physicalcpu 2>/dev/null)"
[ -z "$PHYSICAL_CORES" ] && PHYSICAL_CORES="$(nproc 2>/dev/null)"
[ -z "$PHYSICAL_CORES" ] && PHYSICAL_CORES=4
THREADS="$PHYSICAL_CORES"

MODEL_CHOICE="${1:-}"
MODEL=""
case "$MODEL_CHOICE" in
  qwen2.5-coder|qwen) MODEL="$SCRIPT_DIR/models/qwen2.5-coder.gguf" ;;
  qwen3-30b)          MODEL="$SCRIPT_DIR/models/qwen3-30b.gguf" ;;
  nanbeige)            MODEL="$SCRIPT_DIR/models/nanbeige.gguf" ;;
  "") ;;
  *)
    [ -f "$SCRIPT_DIR/models/$MODEL_CHOICE" ]        && MODEL="$SCRIPT_DIR/models/$MODEL_CHOICE"
    [ -z "$MODEL" ] && [ -f "$SCRIPT_DIR/models/$MODEL_CHOICE.gguf" ] && MODEL="$SCRIPT_DIR/models/$MODEL_CHOICE.gguf"
    ;;
esac
if [ -z "$MODEL" ]; then
  MODEL_FILES=()
  while IFS= read -r -d '' f; do MODEL_FILES+=("$(basename "$f")"); done \
    < <(find "$SCRIPT_DIR/models" -maxdepth 1 -iname "*.gguf" -print0 2>/dev/null | sort -z)
  if [ "${#MODEL_FILES[@]}" -eq 0 ]; then
    echo "No .gguf files found in $SCRIPT_DIR/models. Run install.sh's model step first."
    exit 1
  elif [ -n "$MODEL_CHOICE" ]; then
    echo "Unknown model '$MODEL_CHOICE'. Available: ${MODEL_FILES[*]}"
    exit 1
  else
    MODEL="$SCRIPT_DIR/models/${MODEL_FILES[0]}"
    echo "No model specified — using ${MODEL_FILES[0]}."
  fi
fi
MODEL_CHOICE="$(basename "$MODEL" .gguf)"

STARTED_KOBOLD=0
HISTORY_FILE="$(mktemp)"
echo '[]' > "$HISTORY_FILE"

cleanup() {
  rm -f "$HISTORY_FILE" "$HISTORY_FILE.tmp"
  if [ "$STARTED_KOBOLD" = "1" ]; then
    echo "Stopping koboldcpp (pid $KOBOLD_PID) ..."
    kill "$KOBOLD_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if curl -s -o /dev/null "http://127.0.0.1:$PORT/v1/models"; then
  echo "koboldcpp already running on port $PORT — reusing it (model may differ from '$MODEL_CHOICE' if it was started separately)."
else
  echo "Starting koboldcpp ($MODEL_CHOICE) on port $PORT ..."
  "$BIN_DIR/koboldcpp" \
    --model "$MODEL" \
    --port "$PORT" \
    --host 127.0.0.1 \
    --contextsize 8192 \
    --batchsize 2048 \
    --threads "$THREADS" \
    > "$LOG" 2>&1 &
  KOBOLD_PID=$!
  STARTED_KOBOLD=1

  echo "Waiting for koboldcpp to come up ..."
  for i in $(seq 1 60); do
    if curl -s -o /dev/null "http://127.0.0.1:$PORT/v1/models"; then
      echo "koboldcpp is ready."
      break
    fi
    if ! kill -0 "$KOBOLD_PID" 2>/dev/null; then
      echo "koboldcpp exited early — check $LOG"
      cat "$LOG"
      exit 1
    fi
    sleep 2
  done
fi

echo ""
echo "Terminal chat ready. Model: $MODEL_CHOICE. Type 'exit' or 'quit' to leave."
while true; do
  printf "\nYou: "
  IFS= read -r LINE || break
  case "$LINE" in
    exit|quit) break ;;
    "") continue ;;
  esac

  "$JQ_BIN" --arg content "$LINE" '. + [{"role":"user","content":$content}]' "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
  mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"

  REQUEST="$("$JQ_BIN" -n --argjson messages "$(cat "$HISTORY_FILE")" '{model:"local",messages:$messages,stream:false}')"
  RESPONSE="$(curl -s "http://127.0.0.1:$PORT/v1/chat/completions" -H "Content-Type: application/json" -d "$REQUEST")"
  REPLY="$(printf '%s' "$RESPONSE" | "$JQ_BIN" -r '.choices[0].message.content // "[no response — check koboldcpp.log]"')"

  printf "\nAssistant: %s\n" "$REPLY"

  "$JQ_BIN" --arg content "$REPLY" '. + [{"role":"assistant","content":$content}] | if length > 20 then .[-20:] else . end' "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
  mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
done
