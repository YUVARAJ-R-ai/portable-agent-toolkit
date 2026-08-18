# Claude Code Component (Optional)

Installs the real, standalone Claude Code CLI (no Node/npm needed at
runtime) pre-configured so it works on any host without a login flow each
time — but it is fundamentally different from the rest of this toolkit:

- It needs a **real internet connection** and your **actual Anthropic
  account and billing** (Pro/Max/Team/Enterprise). It never talks to the
  local koboldcpp server.
- Nothing about it can be auto-provisioned — you complete a one-time
  browser OAuth step yourself after install.

## One-time setup

```bash
bin/claude-code setup-token
```
Approve access in the browser tab that opens. Copy the printed token and
save it as the **only** content of:
```
claude-code/token.txt
```
`claude-code.sh` refuses to start and prints these exact instructions again
if this file is missing or empty.

The token is valid for 1 year. To rotate it, repeat the step above and
overwrite the file.

## Security tradeoff: plaintext token storage

The token is stored as a **plaintext file**, trading zero-friction launches
for a real risk: if this install directory is ever lost, copied, or shared,
whoever has it can use Claude Code under your account and billing until you
revoke it.

**If that happens**: go to [claude.ai](https://claude.ai) → **Settings →
Claude Code**, find the authorization, and click the trash-can icon. This
invalidates the token on Anthropic's side immediately — it works even if
you no longer have the install directory.

## How it keeps the host clean

- `CLAUDE_CODE_OAUTH_TOKEN` is exported inline right before launch — this
  env var takes priority over OS keychain/Credential Manager lookups on
  every platform (the documented mechanism for headless/CI use), so
  authentication never touches the host's real keychain at all.
- `CLAUDE_CONFIG_DIR` redirects most of Claude Code's state
  (`.credentials.json`, `projects/`, etc.) into `claude-code/config/`
  instead of the host's real `~/.claude`.
- **Known caveat**: `CLAUDE_CONFIG_DIR` does not stop a project-local
  `.claude/settings.local.json` from being created wherever the current
  working directory is (a still-open upstream limitation). Worked around by
  `cd`-ing into `claude-code/workspace/` before launching, so that file
  lands there too, not on the host.

## Flags

```bash
bash claude-code.sh --skip-permissions   # -y : every tool call runs with NO confirmation
bash claude-code.sh --resume              # -r : resume a previous session (interactive picker)
bash claude-code.sh --continue            # -c : jump into the most recent session
```
`--skip-permissions` is deliberately not the default and not reachable via
Shift+Tab's mode cycle inside a session — opt in per launch only.

Session history is keyed by this workspace's absolute path, which differs
per host (different install location) — a session started on one machine
may not show up under `--continue` on another. Use plain `--resume` (no ID)
for the interactive picker if history looks empty.
