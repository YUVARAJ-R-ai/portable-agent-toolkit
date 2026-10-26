# Usage: .\update.bat <target_dir>
# Mirrors update.sh. Untested (no Windows hardware available).
param([Parameter(Mandatory)][string]$Target)
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
. "$ScriptDir\lib\common.ps1"

$versionsFile = Join-Path $Target ".versions.json"
if (-not (Test-Path $versionsFile)) {
    Write-Host "No .versions.json found at $Target -- not a previous install.sh/install.ps1 target." -ForegroundColor Red
    exit 1
}
$manifest = Get-Content $versionsFile -Raw | ConvertFrom-Json

$GumExe = Join-Path $Target "bin\windows\gum-windows-amd64.exe"
if (-not (Test-Path $GumExe)) { $GumExe = Join-Path $Target "bin\windows\gum.exe" }
if (-not (Test-Path $GumExe)) { $GumExe = Join-Path $Target "bin\gum.exe" }
$HasGum = $false
if ($GumExe -and (Test-Path $GumExe)) {
    try { & $GumExe --version 2>&1 | Out-Null; $HasGum = $true } catch { $HasGum = $false }
}

Write-Host "Checking for updates ..."
$repos = @{
    "koboldcpp" = "LostRuins/koboldcpp"
    "opencode"  = "anomalyco/opencode"
    "goose"     = "block/goose"
    "gum"       = "charmbracelet/gum"
    "jq"        = "jqlang/jq"
}
foreach ($name in $repos.Keys) {
    try {
        $latest = Get-LatestGithubRelease -Repo $repos[$name]
        Write-Host "  $name`: latest is $latest"
    } catch {
        Write-Host "  $name`: could not fetch latest release tag" -ForegroundColor Yellow
    }
}

$choices = @("Runtime scripts & RAG corpus (refresh from toolkit repo)", "Core agent stack (koboldcpp, OpenCode, Goose, gum, jq)")
if ($manifest.components -match "dev") { $choices += "Dev environment (zig, rust, node, python)" }
if ($manifest.components -match "claude-code") { $choices += "Claude Code" }
if ($manifest.components -match "agy-cli") { $choices += "Agy CLI" }

$selected = ""
if ($HasGum) {
    $selected = & $GumExe choose --no-limit --header "Select components to update/refresh:" `
        --cursor.foreground 212 --selected.foreground 212 $choices
} else {
    Write-Host "Select components to update/refresh:"
    for ($i = 0; $i -lt $choices.Count; $i++) {
        Write-Host "  $($i + 1). $($choices[$i])"
    }
    $in = Read-Host "Enter numbers separated by comma (e.g. 1,2), or press enter for all"
    if (-not $in) {
        $selected = $choices -join "`n"
    } else {
        $nums = $in -split ","
        $selArr = @()
        foreach ($n in $nums) {
            $idx = [int]$n.Trim() - 1
            if ($idx -ge 0 -and $idx -lt $choices.Count) { $selArr += $choices[$idx] }
        }
        $selected = $selArr -join "`n"
    }
}

if (-not $selected) { Write-Host "Nothing selected -- no changes made."; exit 0 }

if ($selected -match "Runtime scripts") {
    Write-Host "== Deploying runtime scripts, RAG corpus, and config =="
    Copy-Item "$ScriptDir\runtime\*" $Target -Recurse -Force
    New-Item -ItemType Directory -Force -Path (Join-Path $Target "rag") | Out-Null
    Copy-Item "$ScriptDir\rag\*" (Join-Path $Target "rag") -Recurse -Force
    New-Item -ItemType Directory -Force -Path (Join-Path $Target "goose-config") | Out-Null
    if (Test-Path "$ScriptDir\goose-config") {
        Copy-Item "$ScriptDir\goose-config\*" (Join-Path $Target "goose-config") -Recurse -Force
    }
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
$manifestJson = $manifest | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($versionsFile, $manifestJson, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Update complete." -ForegroundColor Green
