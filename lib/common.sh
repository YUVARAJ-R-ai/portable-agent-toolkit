#!/usr/bin/env bash
# Shared helpers for install.sh/update.sh/components/*.sh. Source this, don't
# execute it directly. Every component script in this project follows the
# same rule: download a versioned release archive, verify its checksum,
# extract into $TARGET (never touch the host's real ~/.cargo, ~/.npm, system
# PATH, package manager, etc). This file exists so that rule is implemented
# once, not copy-pasted with drift across every component.
set -e

# --- OS / arch detection -----------------------------------------------
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "mac" ;;
    Linux)  echo "linux" ;;
    *)      echo "unknown" ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "unknown" ;;
  esac
}

# Physical (not logical/SMT) CPU core count — llama.cpp-style CPU inference is
# generally not helped by hyperthreads, they mostly add cache/memory-bandwidth
# contention for compute-bound work. Same detection used for koboldcpp
# --threads across the whole stack.
physical_cores() {
  local n=""
  n="$(awk -F: '/cpu cores/{print $2; exit}' /proc/cpuinfo 2>/dev/null | tr -d ' ')"
  [ -z "$n" ] && n="$(sysctl -n hw.physicalcpu 2>/dev/null)"
  [ -z "$n" ] && n="$(nproc 2>/dev/null)"
  [ -z "$n" ] && n=4
  echo "$n"
}

# Total system RAM in GB (rounded down) — used to warn before a model
# download that clearly won't fit comfortably in memory.
total_ram_gb() {
  local kb=""
  kb="$(awk '/MemTotal/{print $2; exit}' /proc/meminfo 2>/dev/null)"
  if [ -n "$kb" ]; then
    echo $((kb / 1024 / 1024))
    return
  fi
  local bytes=""
  bytes="$(sysctl -n hw.memsize 2>/dev/null)"
  if [ -n "$bytes" ]; then
    echo $((bytes / 1024 / 1024 / 1024))
    return
  fi
  echo 0
}

# --- Download + verify ---------------------------------------------------
# download_verify <url> <dest_file> [sha256]
# If sha256 is given, verifies it and aborts on mismatch (never silently
# trusts a partial/corrupted/tampered download). If omitted, downloads
# without verification (used only where no fixed-content checksum exists,
# e.g. a "latest" API redirect) — components should prefer pinned URLs with
# checksums wherever the upstream publishes one.
download_verify() {
  local url="$1" dest="$2" expected_sha="${3:-}"
  mkdir -p "$(dirname "$dest")"
  echo "  downloading: $(basename "$dest")"
  curl -fL --progress-bar "$url" -o "$dest"
  if [ -n "$expected_sha" ]; then
    local actual_sha
    if command -v sha256sum >/dev/null 2>&1; then
      actual_sha="$(sha256sum "$dest" | awk '{print $1}')"
    else
      actual_sha="$(shasum -a 256 "$dest" | awk '{print $1}')"
    fi
    if [ "$actual_sha" != "$expected_sha" ]; then
      echo "  CHECKSUM MISMATCH for $(basename "$dest")" >&2
      echo "    expected: $expected_sha" >&2
      echo "    actual:   $actual_sha" >&2
      rm -f "$dest"
      exit 1
    fi
    echo "  checksum OK"
  fi
}

# --- gum bootstrap ---------------------------------------------------------
# The installer needs gum before it can draw any TUI, but the target machine
# has nothing yet — so this is the one binary fetched with a hardcoded
# fallback path (bin/gum) rather than assuming it's already on $TARGET.
ensure_gum() {
  local target="$1"
  local os arch gum_bin
  os="$(detect_os)"
  arch="$(detect_arch)"
  case "$os" in
    mac)   gum_bin="$target/bin/mac/gum-macos-${arch}" ;;
    *)     gum_bin="$target/bin/gum-linux-${arch/x64/amd64}" ;;
  esac
  if [ -x "$gum_bin" ]; then
    echo "$gum_bin"
    return
  fi
  local version="0.17.0"
  local platform_tag=""
  case "$os-$arch" in
    linux-x64)  platform_tag="Linux_x86_64" ;;
    linux-arm64) platform_tag="Linux_arm64" ;;
    mac-arm64)  platform_tag="Darwin_arm64" ;;
    mac-x64)    platform_tag="Darwin_x86_64" ;;
    *) echo "Unsupported platform for gum: $os-$arch" >&2; exit 1 ;;
  esac
  local url="https://github.com/charmbracelet/gum/releases/download/v${version}/gum_${version}_${platform_tag}.tar.gz"
  local tmp
  tmp="$(mktemp -d)"
  curl -fL --progress-bar "$url" -o "$tmp/gum.tar.gz"
  tar -xzf "$tmp/gum.tar.gz" -C "$tmp"
  mkdir -p "$(dirname "$gum_bin")"
  cp "$tmp/gum_${version}_${platform_tag}/gum" "$gum_bin"
  chmod +x "$gum_bin"
  rm -rf "$tmp"
  echo "$gum_bin"
}

# jq is needed by install.sh's own interactive model-picker (to read
# config/models.json) before core-agent-stack.sh has necessarily run yet --
# bootstrap it the same way ensure_gum bootstraps gum, so there's no
# fallback to a possibly-absent system `jq` on PATH.
ensure_jq() {
  local target="$1"
  local os arch jq_bin
  os="$(detect_os)"
  arch="$(detect_arch)"
  jq_bin="$target/bin/jq"
  if [ -x "$jq_bin" ]; then
    echo "$jq_bin"
    return
  fi
  local asset=""
  case "$os-$arch" in
    linux-x64)  asset="jq-linux-amd64" ;;
    linux-arm64) asset="jq-linux-arm64" ;;
    mac-arm64)  asset="jq-macos-arm64" ;;
    mac-x64)    asset="jq-macos-amd64" ;;
    *) echo "Unsupported platform for jq: $os-$arch" >&2; exit 1 ;;
  esac
  local url sha
  url="$(gh_asset_url "jqlang/jq" "$asset")"
  sha="$(curl -fsSL "$(gh_asset_url "jqlang/jq" "sha256sum.txt")" | grep "$asset\$" | awk '{print $1}')"
  download_verify "$url" "$jq_bin" "$sha"
  chmod +x "$jq_bin"
  echo "$jq_bin"
}

# --- GitHub releases helper (used by update.sh and every component) -------
# latest_github_release <owner/repo> -> prints the tag name, e.g. "v1.46.0"
# Deliberately does NOT use `grep -m1` piped directly from curl: grep exiting
# after the first match closes the pipe while curl is still writing, which
# raises a harmless but scary-looking "curl: (23) Failure writing output"
# warning. Buffering the response first avoids it.
latest_github_release() {
  local body
  body="$(curl -fsSL "https://api.github.com/repos/$1/releases/latest")"
  echo "$body" | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
}

# gh_asset_url <owner/repo> <exact_asset_filename> -> full download URL.
# Deliberately does NOT try to correlate "name"/"browser_download_url" JSON
# fields via grep line-windows (tried that first; it's fragile, since the
# distance between the two varies with how much nested object data GitHub
# puts in between, e.g. the uploader sub-object). GitHub's asset download
# URLs are always exactly
# https://github.com/<owner>/<repo>/releases/download/<tag>/<filename> --
# confirmed against a real API response before relying on it -- so this only
# needs the release tag, which is a single unambiguous field.
gh_asset_url() {
  local repo="$1" asset="$2" tag
  tag="$(latest_github_release "$repo")"
  echo "https://github.com/$repo/releases/download/$tag/$asset"
}
