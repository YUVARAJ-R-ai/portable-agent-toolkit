#!/usr/bin/env bash
# Usage: bash dev-environment.sh <target_dir>
# Downloads fully portable, no-host-mutation toolchains into <target_dir>/dev/:
#   dev/zig/     - C and C++ (zig cc / zig c++)
#   dev/rust/    - rustc + cargo (official standalone tarball, no rustup)
#   dev/node/    - node + npm (React via `npm create vite@latest`)
#   dev/python/  - CPython (python-build-standalone, "install_only" build)
# Assumes core-agent-stack.sh already ran, so <target_dir>/bin/jq exists --
# used for JSON parsing here instead of adding a python3 host dependency.
set -e

TARGET="$1"
if [ -z "$TARGET" ]; then
  echo "Usage: bash dev-environment.sh <target_dir>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

OS="$(detect_os)"
ARCH="$(detect_arch)"
JQ="$TARGET/bin/jq"
if [ ! -x "$JQ" ]; then
  echo "Expected $JQ to exist (run core-agent-stack.sh first)." >&2
  exit 1
fi
mkdir -p "$TARGET/dev"

install_zig() {
  echo "== Zig (C/C++) =="
  local plat
  case "$OS-$ARCH" in
    linux-x64) plat="x86_64-linux" ;;
    mac-arm64) plat="aarch64-macos" ;;
    *) echo "No Zig build for $OS-$ARCH" >&2; return 1 ;;
  esac
  local json version url sha
  json="$(curl -fsSL https://ziglang.org/download/index.json)"
  version="$(echo "$json" | "$JQ" -r '[keys[] | select(. != "master")] | sort_by(split(".") | map(tonumber)) | last')"
  url="$(echo "$json" | "$JQ" -r --arg v "$version" --arg p "$plat" '.[$v][$p].tarball')"
  sha="$(echo "$json" | "$JQ" -r --arg v "$version" --arg p "$plat" '.[$v][$p].shasum')"
  echo "  version $version"
  local tmp; tmp="$(mktemp -d)"
  local fname; fname="$(basename "$url")"
  download_verify "$url" "$tmp/$fname" "$sha"
  rm -rf "$TARGET/dev/zig"
  mkdir -p "$TARGET/dev/zig"
  case "$fname" in
    *.tar.xz) tar -xJf "$tmp/$fname" -C "$tmp" ;;
    *.zip)    unzip -q "$tmp/$fname" -d "$tmp" ;;
  esac
  # the tarball extracts to a single versioned directory; move its contents up
  find "$tmp" -mindepth 1 -maxdepth 1 -type d -exec sh -c 'cp -r "$1"/. "$2"/' _ {} "$TARGET/dev/zig" \;
  rm -rf "$tmp"
  chmod +x "$TARGET/dev/zig/zig" 2>/dev/null || true
  echo "  installed to dev/zig/"
}

install_rust() {
  echo "== Rust (rustc + cargo, no rustup) =="
  local triple
  case "$OS-$ARCH" in
    linux-x64) triple="x86_64-unknown-linux-gnu" ;;
    mac-arm64) triple="aarch64-apple-darwin" ;;
    *) echo "No Rust build for $OS-$ARCH" >&2; return 1 ;;
  esac
  local toml url sha version
  toml="$(curl -fsSL https://static.rust-lang.org/dist/channel-rust-stable.toml)"
  version="$(echo "$toml" | grep -A2 '^\[pkg\.rust\]' | grep '^version' | sed -E 's/version = "([0-9.]+).*/\1/')"
  url="$(echo "$toml" | grep -A5 "\[pkg\.rust\.target\.${triple}\]" | grep '^url' | sed -E 's/url = "(.*)"/\1/')"
  sha="$(echo "$toml" | grep -A5 "\[pkg\.rust\.target\.${triple}\]" | grep '^hash' | sed -E 's/hash = "(.*)"/\1/')"
  echo "  version $version"
  local tmp; tmp="$(mktemp -d)"
  local fname; fname="$(basename "$url")"
  download_verify "$url" "$tmp/$fname" "$sha"
  tar -xzf "$tmp/$fname" -C "$tmp"
  rm -rf "$TARGET/dev/rust"
  mkdir -p "$TARGET/dev/rust"
  # the bundled install.sh does a full local (non-system) install with
  # --prefix -- no rustup, no writes outside $TARGET/dev/rust.
  local extracted_dir="$tmp/rust-${version}-${triple}"
  "$extracted_dir/install.sh" --prefix="$TARGET/dev/rust" --disable-ldconfig >/dev/null
  rm -rf "$tmp"

  # Rust needs a C linker to produce the final binary -- rustc alone only
  # compiles to object files. Requiring the host to already have gcc/clang
  # installed would break this project's "no host dependencies" rule, so use
  # zig cc (already part of this bundle) as the linker instead. Confirmed
  # live during development: without this, `cargo build` fails with
  # "linker `cc` not found" on a host with no system C toolchain; with it,
  # a real cargo build+run succeeds using nothing outside dev/.
  cat > "$TARGET/dev/rust/zigcc-linker" <<EOF
#!/bin/sh
exec "$TARGET/dev/zig/zig" cc "\$@"
EOF
  chmod +x "$TARGET/dev/rust/zigcc-linker"
  cat > "$TARGET/dev/rust/config.toml" <<EOF
[target.${triple}]
linker = "$TARGET/dev/rust/zigcc-linker"
EOF
  echo "  installed to dev/rust/ (linker: zig cc, no system cc/gcc needed)"
}

install_node() {
  echo "== Node.js + npm (React via 'npm create vite@latest') =="
  local plat
  case "$OS-$ARCH" in
    linux-x64) plat="linux-x64" ;;
    mac-arm64) plat="darwin-arm64" ;;
    *) echo "No Node build for $OS-$ARCH" >&2; return 1 ;;
  esac
  local version
  version="$(curl -fsSL https://nodejs.org/dist/index.json | "$JQ" -r '[.[] | select(.lts != false)][0].version')"
  local fname="node-${version}-${plat}.tar.xz"
  local url="https://nodejs.org/dist/${version}/${fname}"
  local sha
  sha="$(curl -fsSL "https://nodejs.org/dist/${version}/SHASUMS256.txt" | grep "$fname\$" | awk '{print $1}')"
  echo "  version $version"
  local tmp; tmp="$(mktemp -d)"
  download_verify "$url" "$tmp/$fname" "$sha"
  tar -xJf "$tmp/$fname" -C "$tmp"
  rm -rf "$TARGET/dev/node"
  mkdir -p "$TARGET/dev/node"
  find "$tmp" -mindepth 1 -maxdepth 1 -type d -exec sh -c 'cp -r "$1"/. "$2"/' _ {} "$TARGET/dev/node" \;
  rm -rf "$tmp"
  echo "  installed to dev/node/"
}

install_python() {
  echo "== Python (python-build-standalone) =="
  local triple
  case "$OS-$ARCH" in
    linux-x64) triple="x86_64-unknown-linux-gnu" ;;
    mac-arm64) triple="aarch64-apple-darwin" ;;
    *) echo "No Python build for $OS-$ARCH" >&2; return 1 ;;
  esac
  local release fname url
  release="$(curl -fsSL "https://api.github.com/repos/astral-sh/python-build-standalone/releases/latest")"
  fname="$(echo "$release" | grep -o "\"cpython-3\\.13\\.[0-9]*+[0-9]*-${triple}-install_only\\.tar\\.gz\"" | head -1 | tr -d '"')"
  if [ -z "$fname" ]; then
    echo "Could not find a 3.13.x install_only build for $triple" >&2
    return 1
  fi
  local tag; tag="$(echo "$release" | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
  url="https://github.com/astral-sh/python-build-standalone/releases/download/${tag}/${fname}"
  echo "  $fname"
  local tmp; tmp="$(mktemp -d)"
  # No published per-file checksum for this project -- same situation as
  # koboldcpp/opencode/goose, mitigated by pinning to the official repo.
  download_verify "$url" "$tmp/$fname"
  tar -xzf "$tmp/$fname" -C "$tmp"
  rm -rf "$TARGET/dev/python"
  mkdir -p "$TARGET/dev/python"
  # python-build-standalone's install_only archive extracts to python/*
  cp -r "$tmp/python/." "$TARGET/dev/python/"
  rm -rf "$tmp"
  echo "  installed to dev/python/"
}

FAILED=0
install_zig    || FAILED=1
install_rust   || FAILED=1
install_node   || FAILED=1
install_python || FAILED=1

echo
echo "Dev environment installed into $TARGET/dev/"
echo "Run 'bash dev.sh' (or dev.bat on Windows) from the install root to enter a"
echo "shell with all four toolchains on PATH."
[ "$FAILED" = "1" ] && exit 1
exit 0
