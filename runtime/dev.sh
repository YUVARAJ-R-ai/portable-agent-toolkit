#!/usr/bin/env bash
# Usage: bash dev.sh
# Drops you into a subshell with the portable C/C++ (zig), Rust (rustc +
# cargo), Node.js/npm, and Python toolchains on PATH -- none of them touch
# your host's real ~/.cargo, ~/.npm, system compilers, or system PATH
# permanently. `exit` (or Ctrl+D) returns you to your normal shell exactly
# as it was before.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_DIR="$SCRIPT_DIR/dev"

if [ ! -d "$DEV_DIR" ]; then
  echo "No dev/ directory found at $DEV_DIR -- run install.sh with the dev"
  echo "environment component selected first."
  exit 1
fi

export PATH="$DEV_DIR/zig:$DEV_DIR/rust/bin:$DEV_DIR/node/bin:$DEV_DIR/python/bin:$PATH"
# Rust: fully local, no rustup. CARGO_HOME also holds config.toml, which
# points cargo's linker at zig cc (see components/dev-environment.sh) so
# `cargo build` works with no system C compiler at all.
export CARGO_HOME="$DEV_DIR/rust"
export RUSTUP_HOME="$DEV_DIR/rust"
export npm_config_cache="$DEV_DIR/node/cache"
export PIP_CACHE_DIR="$DEV_DIR/python/cache"
mkdir -p "$DEV_DIR/node/cache" "$DEV_DIR/python/cache"

echo "Portable dev environment active. Available:"
[ -x "$DEV_DIR/zig/zig" ]           && echo "  zig     $("$DEV_DIR/zig/zig" version)  (zig cc / zig c++ for C and C++)"
[ -x "$DEV_DIR/rust/bin/rustc" ]    && echo "  rustc   $("$DEV_DIR/rust/bin/rustc" --version | awk '{print $2}')"
[ -x "$DEV_DIR/rust/bin/cargo" ]    && echo "  cargo   $("$DEV_DIR/rust/bin/cargo" --version | awk '{print $2}')"
[ -x "$DEV_DIR/node/bin/node" ]     && echo "  node    $("$DEV_DIR/node/bin/node" --version)  (React: npm create vite@latest)"
[ -x "$DEV_DIR/node/bin/npm" ]      && echo "  npm     $("$DEV_DIR/node/bin/npm" --version)"
[ -x "$DEV_DIR/python/bin/python3" ] && echo "  python3 $("$DEV_DIR/python/bin/python3" --version 2>&1 | awk '{print $2}')"
echo
echo "Type 'exit' to leave and return your shell to normal."
echo

exec "${SHELL:-/bin/bash}"
