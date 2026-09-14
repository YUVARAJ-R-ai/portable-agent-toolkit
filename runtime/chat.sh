#!/usr/bin/env bash
# Usage: bash chat.sh [model]
# Terminal chat with the local model featuring real-time SSE token streaming,
# ANSI-styled interface, interactive slash commands, and hot-key controls.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
LOG="$SCRIPT_DIR/koboldcpp.log"
PORT=5001

# Binary lookups with architecture fallbacks
KOBOLD_BIN="$BIN_DIR/koboldcpp"
[ ! -x "$KOBOLD_BIN" ] && KOBOLD_BIN="$(find "$BIN_DIR" -maxdepth 1 -name "koboldcpp*" -type f 2>/dev/null | head -1)"

JQ_BIN="$BIN_DIR/jq"
[ ! -x "$JQ_BIN" ] && JQ_BIN="$(find "$BIN_DIR" -maxdepth 1 -name "jq*" -type f 2>/dev/null | head -1)"
[ -z "$JQ_BIN" ] && command -v jq >/dev/null 2>&1 && JQ_BIN="$(command -v jq)"

if [ -z "$JQ_BIN" ]; then
  echo "Error: jq is required but not found in $BIN_DIR or PATH." >&2
  exit 1
fi

# ANSI Colors & Formatting
BOLD="\033[1m"
DIM="\033[2m"
ITALIC="\033[3m"
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
GRAY="\033[38;5;242m"
RESET="\033[0m"

# Auto-detect optimal thread count
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
    echo -e "${RED}No .gguf files found in $SCRIPT_DIR/models.${RESET} Run install.sh's model step first."
    exit 1
  elif [ -n "$MODEL_CHOICE" ]; then
    echo -e "${RED}Unknown model '$MODEL_CHOICE'.${RESET} Available: ${MODEL_FILES[*]}"
    exit 1
  else
    MODEL="$SCRIPT_DIR/models/${MODEL_FILES[0]}"
  fi
fi
MODEL_NAME="$(basename "$MODEL" .gguf)"

STARTED_KOBOLD=0
HISTORY_FILE="$(mktemp)"
echo '[]' > "$HISTORY_FILE"

cleanup() {
  rm -f "$HISTORY_FILE" "$HISTORY_FILE.tmp"
  if [ "$STARTED_KOBOLD" = "1" ]; then
    echo -e "\n${DIM}Stopping background koboldcpp (pid $KOBOLD_PID) ...${RESET}"
    kill "$KOBOLD_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Verify or launch local LLM server
if curl -s -o /dev/null "http://127.0.0.1:$PORT/v1/models"; then
  echo -e "${DIM}koboldcpp is already running on port $PORT — connected.${RESET}"
else
  echo -e "${DIM}Starting koboldcpp ($MODEL_NAME) on port $PORT ...${RESET}"
  if [ ! -x "$KOBOLD_BIN" ]; then
    echo -e "${RED}Error: koboldcpp binary not found in $BIN_DIR${RESET}"
    exit 1
  fi
  "$KOBOLD_BIN" \
    --model "$MODEL" \
    --port "$PORT" \
    --host 127.0.0.1 \
    --contextsize 8192 \
    --batchsize 2048 \
    --threads "$THREADS" \
    > "$LOG" 2>&1 &
  KOBOLD_PID=$!
  STARTED_KOBOLD=1

  printf "${DIM}Waiting for model to load into memory...${RESET}"
  for i in $(seq 1 60); do
    if curl -s -o /dev/null "http://127.0.0.1:$PORT/v1/models"; then
      echo -e " ${GREEN}ready!${RESET}"
      break
    fi
    if ! kill -0 "$KOBOLD_PID" 2>/dev/null; then
      echo -e "\n${RED}koboldcpp exited early — check $LOG${RESET}"
      cat "$LOG"
      exit 1
    fi
    printf "."
    sleep 2
  done
fi

# Print beautiful banner
echo ""
echo -e "${GRAY}┌─────────────────────────────────────────────────────────────┐${RESET}"
echo -e "${GRAY}│${RESET}  ${BOLD}Portable Agent Toolkit — Streaming Terminal Chat${RESET}          ${GRAY}│${RESET}"
echo -e "${GRAY}│${RESET}  ${DIM}Model:${RESET}   ${CYAN}$MODEL_NAME${RESET}"
echo -e "${GRAY}│${RESET}  ${DIM}Server:${RESET}  ${GREEN}http://127.0.0.1:$PORT${RESET} ${DIM}(koboldcpp)${RESET}"
echo -e "${GRAY}│${RESET}  ${DIM}Threads:${RESET} ${YELLOW}$THREADS cores${RESET} ${DIM}| Context: 8192 tokens | Stream: ON${RESET}"
echo -e "${GRAY}│${RESET}"
echo -e "${GRAY}│${RESET}  ${DIM}Commands:${RESET} ${BOLD}/clear${RESET} ${DIM}(reset)${RESET}  ${BOLD}/model${RESET} ${DIM}(info)${RESET}  ${BOLD}/exit${RESET} ${DIM}(quit)${RESET}           ${GRAY}│${RESET}"
echo -e "${GRAY}└─────────────────────────────────────────────────────────────┘${RESET}"

while true; do
  echo ""
  printf "${CYAN}❯ You:${RESET} "
  IFS= read -r -e LINE || break

  # Trim leading/trailing whitespace
  LINE="$(echo "$LINE" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

  case "$LINE" in
    exit|quit|/exit|/quit|/q)
      echo -e "${DIM}Goodbye!${RESET}"
      break
      ;;
    /clear|/reset)
      echo '[]' > "$HISTORY_FILE"
      echo -e "${GREEN}✓ Conversation history cleared.${RESET}"
      continue
      ;;
    /model|/info)
      echo -e "${DIM}Model File:    ${RESET}${BOLD}$MODEL${RESET}"
      echo -e "${DIM}Active Server: ${RESET}http://127.0.0.1:$PORT"
      echo -e "${DIM}Threads:       ${RESET}$THREADS cores"
      echo -e "${DIM}History Turns: ${RESET}$("$JQ_BIN" 'length' "$HISTORY_FILE" 2>/dev/null || echo 0)"
      continue
      ;;
    /help)
      echo -e "${BOLD}Available Commands:${RESET}"
      echo -e "  ${CYAN}/clear${RESET}        Reset conversation context and start fresh"
      echo -e "  ${CYAN}/model${RESET}        Show active model filename, memory, and history stats"
      echo -e "  ${CYAN}/help${RESET}         Show this help guide"
      echo -e "  ${CYAN}/exit${RESET}, ${CYAN}quit${RESET}   Exit chat session"
      continue
      ;;
    "")
      continue
      ;;
  esac

  # Append user query to history
  "$JQ_BIN" --arg content "$LINE" '. + [{"role":"user","content":$content}]' "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
  mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"

  # Build OpenAI-compatible SSE request with stream: true
  REQUEST="$("$JQ_BIN" -n --argjson messages "$(cat "$HISTORY_FILE")" '{model:"local",messages:$messages,stream:true}')"

  printf "\n${MAGENTA}✦ Assistant:${RESET} "

  RESPONSE_FILE="$(mktemp)"
  RAW_STREAM="$(mktemp)"

  # Subshell runs curl | jq pipeline with interrupt handling
  (
    trap 'exit 130' INT
    curl -N -s -X POST "http://127.0.0.1:$PORT/v1/chat/completions" \
      -H "Content-Type: application/json" \
      -d "$REQUEST" | tee "$RAW_STREAM" | \
      "$JQ_BIN" -j -R --unbuffered '
        if startswith("data: ") and (ltrimstr("data: ") != "[DONE]") then
          (ltrimstr("data: ") | fromjson? | .choices[0].delta.content // empty)
        else
          empty
        end
      ' | tee "$RESPONSE_FILE"
  )
  STATUS=$?
  echo "" # Trailing newline after stream ends

  if [ "$STATUS" = "130" ]; then
    echo -e "${YELLOW}[Generation stopped by user]${RESET}"
  fi

  REPLY="$(cat "$RESPONSE_FILE" 2>/dev/null || true)"
  if [ -z "$REPLY" ] && [ "$STATUS" != "130" ]; then
    ERR_MSG="$("$JQ_BIN" -r '.error.message // .detail // empty' "$RAW_STREAM" 2>/dev/null || true)"
    if [ -n "$ERR_MSG" ]; then
      echo -e "${RED}Server Error:${RESET} $ERR_MSG"
    else
      echo -e "${YELLOW}[No response received — check $LOG]${RESET}"
    fi
  elif [ -n "$REPLY" ]; then
    # Keep last 20 messages to stay well within context limit
    "$JQ_BIN" --arg content "$REPLY" '. + [{"role":"assistant","content":$content}] | if length > 20 then .[-20:] else . end' "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
    mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
  fi

  rm -f "$RESPONSE_FILE" "$RAW_STREAM"
  echo -e "${GRAY}─────────────────────────────────────────────────────────────${RESET}"
done
