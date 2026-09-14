# Models

`install.sh` reads `config/models.json` and offers a multi-select picker.
Adding a new model later means editing that one file — no code changes.

| id | Display name | Source | Size | RAM guidance |
|---|---|---|---|---|
| `qwen2.5-coder` | Qwen2.5-Coder 7B (recommended default) | [`Qwen/Qwen2.5-Coder-7B-Instruct-GGUF`](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF) | ~4.7GB | Runs fine on most modern laptops |
| `qwen3-30b` | Qwen3-30B-A3B (large, MoE, fast on CPU) | [`Qwen/Qwen3-30B-A3B-GGUF`](https://huggingface.co/Qwen/Qwen3-30B-A3B-GGUF) | 18.6GB | Needs ~20GB+ RAM — installer warns if your machine has less, but doesn't block the download |
| `nanbeige` | Nanbeige4.2 3B (smallest, lowest RAM) | [`bartowski/Nanbeige_Nanbeige4.2-3B-GGUF`](https://huggingface.co/bartowski/Nanbeige_Nanbeige4.2-3B-GGUF) | 4.43GB | Runs on almost anything |

## Why Qwen3-30B-A3B despite its size

It's a **Mixture-of-Experts** model — 30B total parameters, but only ~3B
active per token. On CPU-only hardware (this project's default, no GPU
assumed), that means generation speed closer to a 3B dense model despite
the much larger download and RAM footprint. If your machine has the RAM for
it, it's a meaningfully more capable model than the two smaller options at
a similar *speed* (not disk/RAM) cost.

## Adding a model

Add an entry to `config/models.json`:
```json
{
  "id": "your-model-id",
  "display_name": "Shown in the installer's picker",
  "repo": "org/Your-Model-GGUF",
  "file": "exact-filename.gguf",
  "size_gb": 5.0,
  "ram_warning_gb": 0,
  "default_selected": false,
  "notes": "Anything worth knowing before someone picks this."
}
```
`repo`/`file` must point at a real HuggingFace GGUF file — `models.sh`
downloads from `https://huggingface.co/<repo>/resolve/main/<file>`. Verify
the file actually loads in koboldcpp (`bin/koboldcpp --model <file>
--foreground` and check for `Load Text Model OK: True`) before shipping the
change — a model that fails to load is a worse experience than one missing
from the list entirely.

`start.sh` and `start.ps1` dynamically detect any `.gguf` files present in
`<target>/models/` and automatically register them in `workspace/opencode.json`
at runtime, so newly added models work seamlessly in both OpenCode and Goose.
