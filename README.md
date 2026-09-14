# Portable Agent Toolkit

A fully offline, zero-host-mutation local AI coding-agent stack you can install anywhere with one script — a local LLM server, two agentic coding orchestrators, an offline tool-call RAG system for algorithms, an optional portable dev environment (C/C++/Rust/Node.js/React/Python, no host compilers needed), an optional real Claude Code CLI, and an optional portable Antigravity CLI — all downloaded fresh, verified, and installed without touching your system PATH, package managers, or global config.

```bash
bash install.sh
```

A TUI walks you through picking which pieces you want. Windows users can run `install.bat`.

---

## What's in it

| Piece | What it does |
|---|---|
| **koboldcpp** | Runs local GGUF models on CPU (or optional Vulkan/Metal GPU), exposes an OpenAI-compatible API (`http://127.0.0.1:5001/v1`) |
| **OpenCode** + **Goose** | Two independent agentic coding CLIs that talk to the local model — choose whichever you prefer at launch |
| **Tool-call RAG** | Verified DAA (Design & Analysis of Algorithms) reference material that agents look up on demand via a tool call rather than hallucinating — see [docs/rag.md](docs/rag.md) |
| **Model picker** | Multi-select from Qwen2.5-Coder 7B, Qwen3-30B-A3B (MoE, fast on CPU), or Nanbeige4.2 3B — config-driven, easy to add more |
| **Dev environment** *(optional)* | Portable, no-install C/C++ (Zig), Rust (rustc + cargo, no rustup), Node.js/npm (React via Vite), and Python — see [docs/dev-environment.md](docs/dev-environment.md) |
| **Claude Code** *(optional)* | The real, cloud-hosted Claude Code CLI, pre-authenticated once via your own Anthropic subscription — see [docs/claude-code.md](docs/claude-code.md) |
| **Agy CLI** *(optional)* | Portable Google Antigravity CLI with persistent local session storage — see [docs/architecture.md](docs/architecture.md) |

Every binary is downloaded directly from its official release source (GitHub Releases, Hugging Face, static.rust-lang.org, nodejs.org, ziglang.org, anthropic.com) — nothing is bundled in this git repo, keeping the repo lightweight.

---

## Quickstart

### Linux & macOS

```bash
git clone https://github.com/<you>/portable-agent-toolkit
cd portable-agent-toolkit
bash install.sh
```

You will be prompted for an install directory (defaults to `./portable-agent`), optional components, and model downloads.

Then enter the target folder and launch:

```bash
cd portable-agent
bash start.sh          # starts koboldcpp, lets you pick a model + OpenCode/Goose
bash chat.sh            # plain terminal chat, no agent overhead
bash dev.sh              # (if installed) portable C/C++/Rust/Node/Python shell
bash claude-code.sh      # (if installed) real Claude Code CLI
bash agy-cli.sh          # (if installed) portable Antigravity CLI
```

### Windows

```cmd
git clone https://github.com/<you>/portable-agent-toolkit
cd portable-agent-toolkit
install.bat
```

Then run `start.bat` / `chat.bat` / `dev.bat` / `claude-code.bat` / `agy-cli.bat`.

---

## Step-by-Step Guide: Setting Up on a Pendrive / USB Drive

Follow this exact guide to create a plug-and-play AI coding environment on a USB drive that you or a friend can carry and use on any computer without installing dependencies on the host.

### 1. Drive Requirements

* **Capacity**: Minimum **32 GB** (for 1 model + dev environment); **64 GB or 128 GB** strongly recommended if downloading larger models like Qwen3-30B.
* **Speed**: USB 3.0 / 3.1 / 3.2 or an external USB SSD. Reading a 5 GB model from USB 2.0 will be noticeably slower.
* **Filesystem Format**:
  * Format the drive as **exFAT** (recommended for cross-platform Linux, Windows, and macOS support) or **NTFS**.
  * ⚠️ **Do NOT format as FAT32**: FAT32 has a maximum single-file size limit of 4 GB. GGUF model weights (4.5 GB to 19 GB) will fail to save on FAT32.

### 2. Prepare the Pendrive

1. Insert your USB pendrive into your machine.
2. Note the drive mount path:
   * **Linux**: `/media/<username>/PENDRIVE` (or `/run/media/...`)
   * **macOS**: `/Volumes/PENDRIVE`
   * **Windows**: `E:\` (or `D:\`, `F:\`)
3. *(Linux only)*: Ensure the USB drive is mounted with execution permissions (`exec`). If your desktop automounts it with `noexec`, remount it:
   ```bash
   sudo mount -o remount,exec /media/$USER/PENDRIVE
   ```

### 3. Run the Installer Targeting the Pendrive

Clone or download this repository on your computer, then point the installer directly at your pendrive.

#### On Linux / macOS:
```bash
git clone https://github.com/<you>/portable-agent-toolkit
cd portable-agent-toolkit

# Interactive install (prompts for components and models):
bash install.sh --target /media/$USER/PENDRIVE/portable-agent

# Or fully automated scripted install:
bash install.sh \
  --target /media/$USER/PENDRIVE/portable-agent \
  --components core,dev,claude-code \
  --models qwen2.5-coder \
  --yes
```

#### On Windows:
```cmd
git clone https://github.com/<you>/portable-agent-toolkit
cd portable-agent-toolkit

install.bat -Target E:\portable-agent
```

### 4. What Lands on the Pendrive

The pendrive will now contain a completely standalone folder:

```
<pendrive>/portable-agent/
├── start.sh / start.bat         # Launch local server + agent orchestrator
├── chat.sh / chat.bat           # Instant terminal chat with local LLM
├── switch-model.sh / .bat       # Hot-swap loaded model in ~15 seconds
├── rag-search.sh / .bat         # DAA algorithm lookup tool
├── dev.sh / dev.bat             # Enter isolated Zig/Rust/Node/Python shell
├── claude-code.sh / .bat        # Real Claude Code CLI
├── agy-cli.sh / .bat            # Portable Agy CLI
├── bin/                         # koboldcpp, opencode, goose, gum, jq
├── models/                      # Downloaded GGUF models (e.g. qwen2.5-coder.gguf)
├── dev/                         # Standalone toolchains (zig, rust, node, python)
├── rag/                         # Verified algorithm index and markdown topics
├── workspace/                   # Default agent working directory with AGENTS.md
└── .versions.json               # Recorded version manifest
```

Because all scripts dynamically determine their location via relative directory paths (`$SCRIPT_DIR` / `$PSScriptRoot`), changing mount points or drive letters (e.g. `E:\` today, `F:\` on another PC) **will never break the installation**.

---

## How to Run It Anywhere From the Pendrive

### Running the Coding Agent Stack
1. Plug the pendrive into any host machine.
2. Open terminal and navigate into the pendrive folder:
   ```bash
   # Linux / macOS:
   cd /media/$USER/PENDRIVE/portable-agent
   bash start.sh

   # Windows:
   cd E:\portable-agent
   start.bat
   ```
3. Koboldcpp starts serving the local model, and an interactive menu prompts you to choose **OpenCode** or **Goose**.
4. The agent loads with access to the verified algorithm RAG tool, tools to create files, and access to the portable dev toolchains (`zig c++`, `rustc`, `cargo`, `node`, `python3`) directly on `PATH`.

### Hot-Swapping Models
While `start.sh` is running, you can hot-swap the loaded model in another terminal without killing your active agent session:
```bash
bash switch-model.sh                # interactive picker
bash switch-model.sh nanbeige.gguf  # direct swap
```
Windows: `switch-model.bat [model]`.

### Working on an External Project
To point the agent at an existing repo or directory outside the pendrive, specify `--workspace`:
```bash
bash start.sh qwen2.5-coder opencode --workspace /path/to/my-project
```

---

## How to Update Everything on the Pendrive Seamlessly

You do **not** need to re-download multi-gigabyte models or wipe your pendrive to update. The update system refreshes binary executables, updates the runtime scripts and RAG knowledge base, and leaves your downloaded models and project files intact.

### 1. Update Using the Toolkit Repository

From any computer with an internet connection:

```bash
cd portable-agent-toolkit
git pull

# Run update against your pendrive directory:
bash update.sh /media/$USER/PENDRIVE/portable-agent
```

On Windows:
```cmd
cd portable-agent-toolkit
git pull
update.bat E:\portable-agent
```

### 2. What the Seamless Update Does

1. **Checks Upstream Releases**: Compares your installed versions against the latest releases of `koboldcpp`, `opencode`, `goose`, `gum`, `jq`, and `claude-code`.
2. **Interactive Component Selection**: Presents a menu allowing you to choose which components to upgrade.
3. **Refreshes Runtime Scripts & RAG Corpus**: Automatically copies latest launch scripts, bug fixes, and verified algorithm topics from the repo into your pendrive.
4. **Preserves Model Weights**: Your existing `.gguf` files in `models/` are kept untouched, saving gigabytes of bandwidth.
5. **Preserves User Settings**: Existing OAuth credentials (`claude-code/token.txt`), isolated configs (`goose-config/`, `opencode-config/`), and workspace files remain completely untouched.
6. **Updates Manifest**: Writes the new version metadata to `.versions.json`.

---

## Documentation

- [docs/architecture.md](docs/architecture.md) — how all components interact and maintain host isolation
- [docs/dev-environment.md](docs/dev-environment.md) — portable C/C++/Rust/Node/Python toolchains and zero host dependencies
- [docs/models.md](docs/models.md) — model list, RAM requirements, and adding new GGUFs
- [docs/rag.md](docs/rag.md) — tool-call RAG architecture and hallucination prevention
- [docs/claude-code.md](docs/claude-code.md) — optional Claude Code CLI setup and credential storage
- [docs/install.md](docs/install.md) — installer CLI flags reference and scripted automation

---

## License

MIT — see [LICENSE](LICENSE).
