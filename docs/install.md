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
                 --components core,dev,claude-code,agy-cli \
                 --models qwen2.5-coder,nanbeige \
                 --yes
```
- `--target <dir>`: where to install. Created if it doesn't exist.
- `--components <comma-list>`: any of `core` (always included),
  `dev`, `claude-code`, `agy-cli`. Omit to customize.
- `--models <comma-list>`: any `id` from `config/models.json`
  (`qwen2.5-coder`, `qwen3-30b`, `nanbeige`). Omit to install no models —
  you can add them later by re-running `components/models.sh` directly.
- `--yes`: assume default answers for any unspecified flags without interactive prompts.

Any flag left unset falls back to its interactive prompt (unless `--yes` is specified).

## What each component script does, if you want to run one on its own

```bash
bash components/core-agent-stack.sh <target>          # koboldcpp, opencode, goose, gum, jq
bash components/models.sh <target> config/models.json <id> [<id>...]
bash components/dev-environment.sh <target>            # zig, rust, node, python
bash components/claude-code.sh <target>
bash components/agy-cli.sh <target>
```
Each is independent and idempotent-ish (re-running re-downloads current
latest, overwriting what's there) — this is what `update.sh` invokes
under the hood for whichever components you select.

## After install

`install.sh` copies this repo's `runtime/` scripts, `rag/` corpus, and
`config/models.json` into `<target>/` and writes `<target>/.versions.json`.
Running `bash update.sh <target>` checks for updates and allows refreshing
both the binary components and the runtime scripts / RAG corpus in-place.
