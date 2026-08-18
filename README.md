# Portable Agent Toolkit

A fully offline, local AI coding-agent stack you can install anywhere with
one script — a local LLM server, two agentic coding orchestrators, a
hallucination-resistant tool-call RAG system for algorithms, an optional
portable dev environment (C/C++/Rust/Node.js/React/Python, no host compilers
needed), and an optional real Claude Code CLI — all downloaded fresh,
checksum-verified, and installed without touching your system PATH, package
managers, or global config.

```
bash install.sh
```

That's it. A TUI walks you through picking which pieces you want.

## What's in it

| Piece | What it does |
|---|---|
| **koboldcpp** | Runs a local GGUF model, exposes an OpenAI-compatible API |
| **OpenCode** + **Goose** | Two independent agentic coding CLIs, both talk to the same local model — pick whichever you prefer at launch |
| **Tool-call RAG** | 8 verified DAA (Design & Analysis of Algorithms) topics the agents look up on demand instead of guessing from memory — see [docs/rag.md](docs/rag.md) |
| **Model picker** | Multi-select from Qwen2.5-Coder 7B, Qwen3-30B-A3B (MoE, fast on CPU), or Nanbeige4.2 3B — config-driven, easy to add more |
| **Dev environment** *(optional)* | Portable, no-install C/C++ (Zig), Rust (rustc + cargo, no rustup), Node.js/npm (React via Vite), and Python — see [docs/dev-environment.md](docs/dev-environment.md) |
| **Claude Code** *(optional)* | The real, cloud-hosted Claude Code CLI, pre-authenticated once via your own Anthropic subscription — see [docs/claude-code.md](docs/claude-code.md) |

Every binary is downloaded directly from its official source (GitHub
Releases, HuggingFace, static.rust-lang.org, nodejs.org, ziglang.org) and
checksum-verified before use — nothing is bundled into this repo, so the
repo itself stays a few hundred KB of scripts and docs, not gigabytes of
binaries.

## Quickstart

```bash
git clone https://github.com/<you>/portable-agent-toolkit
cd portable-agent-toolkit
bash install.sh
```

You'll be asked where to install (defaults to `./portable-agent`), which
optional components to add, and which model(s) to download. Then:

```bash
cd portable-agent
bash start.sh          # starts koboldcpp, lets you pick a model + OpenCode/Goose
bash chat.sh            # plain terminal chat, no agent overhead
bash dev.sh              # (if installed) portable C/C++/Rust/Node/Python shell
bash claude-code.sh      # (if installed) the real Claude Code CLI
```

Windows: `install.bat`, then `start.bat` / `chat.bat` / `dev.bat` / `claude-code.bat`.

## Why this exists

Most "run an LLM locally" setups either install to your system (polluting
`~/.cargo`, `~/.npm`, global PATH, package managers) or ship as one giant
opinionated Docker image. This is neither — every component is a plain
downloaded binary or portable toolchain living entirely inside one
directory, so it runs the same way on a work laptop, a personal machine, or
a USB drive, and leaves nothing behind on the host beyond that one
directory.

## Updating

```bash
bash update.sh /path/to/your/install
```

Checks each installed component's version against its latest upstream
release and lets you pick what to refresh. Model weights aren't part of the
update flow — swapping models is a separate, deliberate action (see
`bash switch-model.sh` inside an install, or re-run `install.sh`'s model
step to add another one).

## Documentation

- [docs/architecture.md](docs/architecture.md) — how the pieces fit together
- [docs/dev-environment.md](docs/dev-environment.md) — the portable C/C++/Rust/Node/Python toolchains
- [docs/models.md](docs/models.md) — the model list, RAM guidance, how to add a new model
- [docs/rag.md](docs/rag.md) — the tool-call RAG system and why it's built to avoid hallucination
- [docs/claude-code.md](docs/claude-code.md) — the optional Claude Code CLI component
- [docs/install.md](docs/install.md) — full installer flag reference, non-interactive/scripted installs

## License

MIT — see [LICENSE](LICENSE).
