#!/usr/bin/env bash
# In-workspace shim so agents can call this without a ../ path (opencode treats ../ as an external directory and asks or auto-rejects).
exec bash "$(dirname "${BASH_SOURCE[0]}")/../rag-search.sh" "$@"
