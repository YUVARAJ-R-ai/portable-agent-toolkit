#!/usr/bin/env bash
# Usage: bash rag-search.sh "<query>" [--list]
#
# Looks up DAA (Design & Analysis of Algorithms) reference material: verified
# C++ implementations + explanations for the PAT-1, PAT-2 and FAT lab topics
# (greedy, divide & conquer, DP, backtracking, branch & bound, string matching,
# graphs, network flow, geometry, NP verification, approximation, randomized),
# including your lab-report programs with their verified answers, and prints
# the single best-matching topic's full content to stdout.
#
#   bash rag-search.sh --list                 list all topics (id + description), no match needed
#   bash rag-search.sh "huffman coding"        print the huffman_coding topic
#   bash rag-search.sh "how do i sort fast"    ambiguous -> lists close candidates instead of guessing
#   bash rag-search.sh "kadane"                still matches maximum_subarray_dc (both methods live there)
#   bash rag-search.sh "amazon super queens"   matches n_queens_backtracking
#   bash rag-search.sh "mandatory fiber"       matches mst_kruskal_prim
#
# Deliberately conservative: if there's no confident single best match, this
# prints a short "no match" / "ambiguous" message and candidate topic ids
# instead of guessing — returning the WRONG topic's content silently is a much
# worse failure than admitting no match, since it's exactly what causes an
# agent reading this output to hallucinate confidently.
# Windows (Git Bash / MSYS / Cygwin): the Linux binaries in bin/ can't run here, so hand off to the PowerShell twin.
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*)
  exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$(dirname "${BASH_SOURCE[0]}")")\\rag-search.ps1" "$@" ;;
esac
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/rag" ]; then
  RAG_DIR="$SCRIPT_DIR/rag"
elif [ -d "$SCRIPT_DIR/../rag" ]; then
  RAG_DIR="$SCRIPT_DIR/../rag"
else
  RAG_DIR="$SCRIPT_DIR/rag"
fi

INDEX="$RAG_DIR/index.json"
TOPICS_DIR="$RAG_DIR/topics"

if [ -x "$SCRIPT_DIR/bin/jq" ]; then
  JQ_BIN="$SCRIPT_DIR/bin/jq"
elif [ -n "$(find "$SCRIPT_DIR/bin" -maxdepth 1 -name "jq*" -type f 2>/dev/null | head -1)" ]; then
  JQ_BIN="$(find "$SCRIPT_DIR/bin" -maxdepth 1 -name "jq*" -type f 2>/dev/null | head -1)"
elif command -v jq >/dev/null 2>&1; then
  JQ_BIN="$(command -v jq)"
else
  JQ_BIN="$SCRIPT_DIR/bin/jq"
fi

if [ ! -f "$INDEX" ]; then
  echo "RAG index not found at $INDEX" >&2
  exit 1
fi

if [ "${1:-}" = "--list" ]; then
  "$JQ_BIN" -r '.topics[] | "\(.id)  —  \(.description)"' "$INDEX"
  exit 0
fi

QUERY="${1:-}"
if [ -z "$QUERY" ]; then
  echo "Usage: bash rag-search.sh \"<query>\" [--list]" >&2
  exit 1
fi
QUERY_LC="$(echo "$QUERY" | tr '[:upper:]' '[:lower:]')"

IDS=()
FILES=()
CATEGORIES=()
SCORES=()
CANDIDATES=()

while IFS= read -r topic_json; do
  id="$(echo "$topic_json" | "$JQ_BIN" -r '.id')"
  file="$(echo "$topic_json" | "$JQ_BIN" -r '.file')"
  category="$(echo "$topic_json" | "$JQ_BIN" -r '.category')"
  desc="$(echo "$topic_json" | "$JQ_BIN" -r '.description')"
  score=0

  id_as_words="$(echo "$id" | tr '_' ' ')"
  if [[ "$QUERY_LC" == *"$id_as_words"* ]]; then
    score=$((score + ${#id_as_words}))
  fi

  while IFS= read -r alias; do
    alias_lc="$(echo "$alias" | tr '[:upper:]' '[:lower:]')"
    if [[ "$QUERY_LC" == *"$alias_lc"* ]]; then
      score=$((score + ${#alias_lc}))
    fi
  done < <(echo "$topic_json" | "$JQ_BIN" -r '.aliases[]')

  if [ "$score" -gt 0 ]; then
    CANDIDATES+=("$id ($desc) score=$score")
  fi
  IDS+=("$id")
  FILES+=("$file")
  CATEGORIES+=("$category")
  SCORES+=("$score")
done < <("$JQ_BIN" -c '.topics[]' "$INDEX")

# Specificity rule: a query like "divide and conquer maximum subarray" should
# resolve to the specific maximum_subarray_dc topic, not the generic
# divide_and_conquer_overview one — demote an "*_overview" topic's score to 0
# whenever any other topic in the same category also scored > 0.
for i in "${!IDS[@]}"; do
  case "${IDS[$i]}" in
    *_overview)
      for j in "${!IDS[@]}"; do
        if [ "$i" != "$j" ] && [ "${CATEGORIES[$j]}" = "${CATEGORIES[$i]}" ] && [ "${SCORES[$j]}" -gt 0 ]; then
          SCORES[$i]=0
          break
        fi
      done
      ;;
  esac
done

BEST_ID=""
BEST_FILE=""
BEST_SCORE=0
BEST_COUNT=0
for i in "${!IDS[@]}"; do
  score="${SCORES[$i]}"
  if [ "$score" -gt "$BEST_SCORE" ]; then
    BEST_SCORE=$score
    BEST_ID="${IDS[$i]}"
    BEST_FILE="${FILES[$i]}"
    BEST_COUNT=1
  elif [ "$score" -eq "$BEST_SCORE" ] && [ "$score" -gt 0 ]; then
    BEST_COUNT=$((BEST_COUNT + 1))
  fi
done

if [ "$BEST_SCORE" -eq 0 ]; then
  echo "NO MATCH: nothing in this corpus matches \"$QUERY\"."
  echo "Available topics (run: bash rag-search.sh --list):"
  "$JQ_BIN" -r '.topics[] | "  - \(.id): \(.description)"' "$INDEX"
  echo "Do not invent an answer as if it came from this corpus — either say the"
  echo "topic isn't covered, or answer from general knowledge and say so clearly."
  exit 0
fi

if [ "$BEST_COUNT" -gt 1 ]; then
  echo "AMBIGUOUS: more than one topic matched \"$QUERY\" equally well:"
  printf '  %s\n' "${CANDIDATES[@]}"
  echo "Pick the specific one you need and re-run, e.g.:"
  echo "  bash rag-search.sh \"<exact topic id or a more specific phrase>\""
  exit 0
fi

cat "$TOPICS_DIR/$BEST_FILE"
