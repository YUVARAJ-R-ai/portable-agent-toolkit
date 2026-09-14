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

$choices = @("Runtime scripts & RAG corpus (refresh from toolkit repo)", "Core agent stack (koboldcpp, OpenCode, Goose, gum, jq)")
if ($manifest.components -match "dev") { $choices += "Dev environment (zig, rust, node, python)" }
if ($manifest.components -match "claude-code") { $choices += "Claude Code" }
if ($manifest.components -match "agy-cli") { $choices += "Agy CLI" }

$selected = & $GumExe choose --no-limit --header "Select components to update/refresh:" `
    --cursor.foreground 212 --selected.foreground 212 $choices
if (-not $selected) { Write-Host "Nothing selected -- no changes made."; exit 0 }

if ($selected -match "Runtime scripts") {
    Write-Host "== Deploying runtime scripts, RAG corpus, and config =="
    Copy-Item "$ScriptDir\runtime\*" $Target -Recurse -Force
    Copy-Item "$ScriptDir\rag" (Join-Path $Target "rag") -Recurse -Force
    New-Item -ItemType Directory -Force -Path (Join-Path $Target "config") | Out-Null
    Copy-Item "$ScriptDir\config\models.json" (Join-Path $Target "config\models.json") -Force
}
if ($selected -match "Core agent stack") {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$ScriptDir\components\core-agent-stack.ps1" -Target $Target
}
if ($selected -match "Dev environment") {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$ScriptDir\components\dev-environment.ps1" -Target $Target
}
if ($selected -match "Claude Code") {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$ScriptDir\components\claude-code.ps1" -Target $Target
}
if ($selected -match "Agy CLI") {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$ScriptDir\components\agy-cli.ps1" -Target $Target
}

$binDir = Join-Path $Target "bin\windows"
$koboldVer = if (Test-Path (Join-Path $binDir "koboldcpp-nocuda.exe")) { try { (& (Join-Path $binDir "koboldcpp-nocuda.exe") --version 2>&1 | Select-Object -First 1) } catch { "" } } else { "" }
$opencodeVer = if (Test-Path (Join-Path $binDir "opencode.exe")) { try { (& (Join-Path $binDir "opencode.exe") --version 2>&1 | Select-Object -First 1) } catch { "" } } else { "" }
$gooseVer = if (Test-Path (Join-Path $binDir "goose.exe")) { try { (& (Join-Path $binDir "goose.exe") --version 2>&1 | Select-Object -First 1) } catch { "" } } else { "" }
$gumVer = if (Test-Path (Join-Path $binDir "gum-windows-amd64.exe")) { try { (& (Join-Path $binDir "gum-windows-amd64.exe") --version 2>&1 | Select-Object -First 1) } catch { "" } } else { "" }
$jqVer = if (Test-Path (Join-Path $binDir "jq-windows-amd64.exe")) { try { (& (Join-Path $binDir "jq-windows-amd64.exe") --version 2>&1 | Select-Object -First 1) } catch { "" } } else { "" }
$agyVer = if (Test-Path (Join-Path $binDir "agy.exe")) { try { (& (Join-Path $binDir "agy.exe") --version 2>&1 | Select-Object -First 1) } catch { "" } } else { "" }

$manifest.installed_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$manifest.versions = @{
    koboldcpp = [string]$koboldVer
    opencode  = [string]$opencodeVer
    goose     = [string]$gooseVer
    gum       = [string]$gumVer
    jq        = [string]$jqVer
    agy       = [string]$agyVer
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content $versionsFile
Write-Host "Update complete."
