#!/usr/bin/env bash
# Usage: bash start.sh [model] [opencode|goose]
# Starts koboldcpp with the chosen model, then lets you pick a coding-agent
# orchestrator (OpenCode or Goose) via an interactive menu, or pass it as the
# 2nd argument to skip the menu. [model] can be a config/models.json id
# (qwen2.5-coder / qwen3-30b / nanbeige), a models/*.gguf filename with or
# without the extension, or omitted -- with no match, any .gguf files under
# models/ are auto-discovered and offered in a picker. Run `bash
# switch-model.sh` in another terminal at any time to hot-swap the running
# model without restarting koboldcpp or the orchestrator session.
# Works on Linux and macOS (auto-detected via `uname`). For Windows, use start.bat.
# Set VULKAN=1 (e.g. `VULKAN=1 bash start.sh`) to A/B test a GPU path.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
WORKSPACE="$SCRIPT_DIR/workspace"
LOG="$SCRIPT_DIR/koboldcpp.log"
PORT=5001

OS="$(uname -s)"
case "$OS" in
  Darwin) GPU_FLAGS="" ;;   # Metal is used automatically on Apple Silicon builds, no explicit flag needed
  *)      GPU_FLAGS=""
          [ -n "$VULKAN" ] && GPU_FLAGS="--usevulkan" ;;
esac
KOBOLD_BIN="$BIN_DIR/koboldcpp"
OPENCODE_BIN="$BIN_DIR/opencode"
GOOSE_BIN="$BIN_DIR/goose"
GUM_BIN="$BIN_DIR/gum"

# koboldcpp's own thread auto-detect commonly under-uses multi-core/SMT CPUs
# -- physical core count (not the full logical/SMT count) is the right
# target for CPU inference speed, confirmed via a controlled A/B benchmark
# during this project's development (~6-18% faster than the auto-detected
# value on a 6-core/12-thread test machine).
PHYSICAL_CORES="$(awk -F: '/cpu cores/{print $2; exit}' /proc/cpuinfo 2>/dev/null | tr -d ' ')"
[ -z "$PHYSICAL_CORES" ] && PHYSICAL_CORES="$(sysctl -n hw.physicalcpu 2>/dev/null)" # macOS
[ -z "$PHYSICAL_CORES" ] && PHYSICAL_CORES="$(nproc 2>/dev/null)"
[ -z "$PHYSICAL_CORES" ] && PHYSICAL_CORES=4
THREADS="$PHYSICAL_CORES"

MODEL_CHOICE="${1:-}"
MODEL=""
case "$MODEL_CHOICE" in
  qwen2.5-coder|qwen) MODEL="$SCRIPT_DIR/models/qwen2.5-coder.gguf" ;;
  qwen3-30b)          MODEL="$SCRIPT_DIR/models/qwen3-30b.gguf" ;;
  nanbeige)            MODEL="$SCRIPT_DIR/models/nanbeige.gguf" ;;
  "") ;; # fall through to auto-discovery below
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
    echo "No .gguf files found in $SCRIPT_DIR/models and '$MODEL_CHOICE' didn't match one."
    echo "Run install.sh's model step first, or usage: bash start.sh [model] [opencode|goose]"
    exit 1
  elif [ -n "$MODEL_CHOICE" ]; then
    echo "Unknown model '$MODEL_CHOICE'. Available: ${MODEL_FILES[*]}"
    exit 1
  elif [ "${#MODEL_FILES[@]}" -eq 1 ]; then
    MODEL="$SCRIPT_DIR/models/${MODEL_FILES[0]}"
  else
    MODEL="$SCRIPT_DIR/models/$("$GUM_BIN" choose "${MODEL_FILES[@]}" \
      --header "Pick a model to load:" \
      --cursor.foreground 212 --selected.foreground 212)"
    [ -z "$MODEL" ] && { echo "No model selected — exiting."; exit 1; }
  fi
fi
API_MODEL_NAME="$(basename "$MODEL" .gguf)"
MODEL_CHOICE="$API_MODEL_NAME"

if curl -s -o /dev/null "http://127.0.0.1:$PORT/v1/models"; then
  echo "koboldcpp is already running on port $PORT — reusing it (model may differ from '$MODEL_CHOICE' if it was started separately)."
  STARTED_KOBOLD=0
else
  echo "Starting koboldcpp ($MODEL_CHOICE) on port $PORT ..."
  # --contextsize 16384: agentic prompts carry a large tool-schema on every
  #   turn, so 8192 overflows; 32768 bloats the KV cache for nothing.
  # --batchsize 2048: the 512 default makes prefill of that token-heavy
  #   context slow; 2048 processes the prompt in fewer, larger chunks.
  # --admin --admindir models/: enables koboldcpp's built-in Admin API,
  #   which auto-lists every .gguf under models/ and can hot-swap the loaded
  #   model without killing this process or its port — see switch-model.sh.
  "$KOBOLD_BIN" \
    --model "$MODEL" \
    --port "$PORT" \
    --host 127.0.0.1 \
    --contextsize 16384 \
    --batchsize 2048 \
    --threads "$THREADS" \
    --admin \
    --admindir "$SCRIPT_DIR/models" \
    $GPU_FLAGS \
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

cleanup() {
  if [ "$STARTED_KOBOLD" = "1" ]; then
    echo "Stopping koboldcpp (pid $KOBOLD_PID) ..."
    kill "$KOBOLD_PID" 2>/dev/null || true
    # A switch-model.sh swap respawns koboldcpp as an entirely new child
    # process via Python multiprocessing, and plain `kill` of only the
    # originally-captured PID does NOT cascade-kill it (confirmed live during
    # development). pkill -f matches every process sharing this exact
    # invocation regardless of which one currently owns the port.
    sleep 1
    pkill -f "$KOBOLD_BIN.*--admindir $SCRIPT_DIR/models" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# --- Pick an orchestrator ---------------------------------------------------
ORCHESTRATOR="${2:-}"
if [ -z "$ORCHESTRATOR" ]; then
  "$GUM_BIN" style --border rounded --padding "0 2" --margin "1 0" \
    --border-foreground 212 --foreground 212 \
    "Portable Agent Toolkit  ·  model: $MODEL_CHOICE"
  ORCHESTRATOR="$("$GUM_BIN" choose "OpenCode" "Goose" \
    --header "Pick a coding-agent orchestrator:" \
    --cursor.foreground 212 --selected.foreground 212)"
fi

if [ -z "$ORCHESTRATOR" ]; then
  echo "No orchestrator selected — exiting."
  exit 1
fi

cd "$WORKSPACE"
case "$(echo "$ORCHESTRATOR" | tr '[:upper:]' '[:lower:]')" in
  opencode)
    "$OPENCODE_BIN"
    ;;
  goose)
    XDG_CONFIG_HOME="$SCRIPT_DIR/goose-config" \
    OPENAI_BASE_URL="http://127.0.0.1:$PORT/v1" \
    OPENAI_API_KEY="not-needed" \
    GOOSE_TELEMETRY_OFF=1 \
    GOOSE_DISABLE_KEYRING=1 \
    GOOSE_DISABLE_SESSION_NAMING=1 \
    "$GOOSE_BIN" session --no-profile --with-builtin developer \
      --provider openai --model "$API_MODEL_NAME"
    ;;
  *)
    echo "Unknown orchestrator '$ORCHESTRATOR'. Usage: bash start.sh [model] [opencode|goose]"
    exit 1
    ;;
esac
