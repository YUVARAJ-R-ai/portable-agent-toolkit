# Architecture

## Layout after install

```
<install target>/
├── start.sh / start.bat+start.ps1        # koboldcpp + OpenCode/Goose menu
├── chat.sh  / chat.bat+chat.ps1          # koboldcpp + plain terminal chat
├── switch-model.sh / .ps1 / .bat         # hot-swap the running model
├── rag-search.sh / .ps1 / .bat           # DAA algorithm RAG lookup
├── claude-code.sh / .ps1 / .bat          # (optional) real Claude Code CLI
├── dev.sh / dev.bat                       # (optional) portable dev-env shell
├── bin/                                    # koboldcpp, opencode, goose, gum, jq[, claude-code]
├── models/                                 # downloaded GGUF files
├── dev/                                    # (optional) zig/ rust/ node/ python/
├── rag/                                    # index.json + topic markdown files
├── config/
│   └── models.json                         # copy of this repo's model list
├── workspace/
│   ├── AGENTS.md                           # auto-loaded by both OpenCode and Goose
│   └── opencode.json                       # points OpenCode at the local koboldcpp endpoint
├── claude-code/                            # (optional) config/ + workspace/ + token.txt
├── goose-config/                           # Goose's config root, kept off your real home dir
└── .versions.json                          # what update.sh compares against
```

## How the pieces talk to each other

koboldcpp serves an OpenAI-compatible API on `http://127.0.0.1:5001`. Every
other piece is just a client of that one endpoint:

- **OpenCode** reads `workspace/opencode.json`, which registers it as a
  custom `@ai-sdk/openai-compatible` provider pointed at that URL.
- **Goose** is given the same URL via `OPENAI_BASE_URL`/`OPENAI_API_KEY` env
  vars set inline by `start.sh`, plus `--provider openai --model <name>` —
  no persistent config file needed.
- **`rag-search.sh`** and **`switch-model.sh`** are plain shell scripts
  invoked by the agents themselves through their built-in `shell` tool
  (both OpenCode and Goose auto-load `workspace/AGENTS.md`, which tells them
  when and how to call these) — not a separate protocol, just the same
  shell-tool access every agentic CLI already has.
- **Claude Code**, if installed, is entirely separate — it needs real
  internet access to Anthropic's API and your own account, and never talks
  to koboldcpp at all.

## Why this design (not a Docker image, not a system install)

- **No host mutation**: nothing writes to your system PATH, package
  managers, `~/.cargo`, `~/.npm`, or global config. Every component's own
  config directory is redirected inside the install target (`XDG_CONFIG_HOME`
  for Goose, `CLAUDE_CONFIG_DIR` for Claude Code, `CARGO_HOME`/`RUSTUP_HOME`
  for Rust, etc.) — confirmed empirically during development by diffing the
  real host config directories before and after a full session.
- **No bundled binaries in the repo**: everything is downloaded fresh from
  its official source and checksum-verified at install time. This keeps the
  git repo itself tiny (scripts + docs + a few KB of JSON) and means you're
  always installing the current release, not whatever was frozen into the
  repo months ago.
- **CPU-first**: the default launch config uses no GPU offload. Every
  binary/toolchain here runs on CPU-only hardware; GPU acceleration
  (`VULKAN=1`) is opt-in, not assumed, since the whole point is running
  identically on whatever machine you actually plug this into.
