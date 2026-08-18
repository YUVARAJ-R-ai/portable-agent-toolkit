# Usage: .\update.bat <target_dir>
# Mirrors update.sh. Untested (no Windows hardware available).
param([Parameter(Mandatory)][string]$Target)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\lib\common.ps1"

$versionsFile = Join-Path $Target ".versions.json"
if (-not (Test-Path $versionsFile)) {
    Write-Host "No .versions.json found at $Target -- not a previous install.sh/install.ps1 target." -ForegroundColor Red
    exit 1
}
$manifest = Get-Content $versionsFile -Raw | ConvertFrom-Json
$GumExe = Join-Path $Target "bin\windows\gum-windows-amd64.exe"

Write-Host "Checking for updates ..."
$repos = @{
    "koboldcpp" = "LostRuins/koboldcpp"
    "opencode"  = "sst/opencode"
    "goose"     = "block/goose"
    "gum"       = "charmbracelet/gum"
    "jq"        = "jqlang/jq"
}
foreach ($name in $repos.Keys) {
    $latest = Get-LatestGithubRelease -Repo $repos[$name]
    Write-Host "  $name`: latest is $latest (re-run components\core-agent-stack.ps1 to refresh)"
}

$choices = @("Core agent stack (koboldcpp, OpenCode, Goose, gum, jq)")
if ($manifest.components -match "dev") { $choices += "Dev environment (zig, rust, node, python)" }
if ($manifest.components -match "claude-code") { $choices += "Claude Code" }

$selected = & $GumExe choose --no-limit --header "Select components to update:" `
    --cursor.foreground 212 --selected.foreground 212 $choices
if (-not $selected) { Write-Host "Nothing selected -- no changes made."; exit 0 }

if ($selected -match "Core agent stack") {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$ScriptDir\components\core-agent-stack.ps1" -Target $Target
}
if ($selected -match "Dev environment") {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$ScriptDir\components\dev-environment.ps1" -Target $Target
}
if ($selected -match "Claude Code") {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$ScriptDir\components\claude-code.ps1" -Target $Target
}

$manifest.installed_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$manifest | ConvertTo-Json | Set-Content $versionsFile
Write-Host "Update complete."
