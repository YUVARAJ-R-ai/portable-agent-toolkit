# Installer Reference

## Interactive (default)

```bash
bash install.sh
```
Prompts for: install directory, optional components (dev environment,
Claude Code), and which model(s) to download.

## Non-interactive / scripted

```bash
bash install.sh --target /path/to/install \
                 --components core,dev,claude-code \
                 --models qwen2.5-coder,nanbeige
```
- `--target <dir>`: where to install. Created if it doesn't exist.
- `--components <comma-list>`: any of `core` (always effectively included),
  `dev`, `claude-code`. Omit `dev`/`claude-code` to skip them.
- `--models <comma-list>`: any `id` from `config/models.json`
  (`qwen2.5-coder`, `qwen3-30b`, `nanbeige`). Omit to install no models —
  you can add them later by re-running `components/models.sh` directly.

Any flag left unset falls back to its interactive prompt — so `bash
install.sh --target /opt/agent` still asks about components and models
interactively, just skips the directory prompt.

## What each component script does, if you want to run one on its own

```bash
bash components/core-agent-stack.sh <target>          # koboldcpp, opencode, goose, gum, jq
bash components/models.sh <target> config/models.json <id> [<id>...]
bash components/dev-environment.sh <target>            # zig, rust, node, python
bash components/claude-code.sh <target>
```
Each is independent and idempotent-ish (re-running re-downloads current
latest, overwriting what's there) — this is exactly what `update.sh` does
under the hood for whichever components you select.

## After install

`install.sh` copies this repo's `runtime/` scripts, `rag/` corpus, and
`config/models.json` into `<target>/` and writes `<target>/.versions.json`.
None of that copying re-runs on `update.sh` — only the binary/toolchain
components do. If you change something in `runtime/` or `rag/` in this repo
after already installing, re-run `install.sh` again (safe — it re-uses
already-downloaded binaries/models where checksums match) to pick up the
change, or just `cp -r runtime/. rag/ <target>/` directly.
