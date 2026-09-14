# Usage: .\install.bat [-Target <dir>] [-Components core,dev] [-Models qwen2.5-coder]
#        (or: powershell -File install.ps1 ...)
# Mirrors install.sh. Untested (no Windows hardware available during
# development) -- see docs/install.md.
param(
    [string]$Target = "",
    [string]$Components = "",
    [string]$Models = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\lib\common.ps1"

if (-not $Target) {
    $Target = Read-Host "Install directory [$(Join-Path (Get-Location) 'portable-agent')]"
    if (-not $Target) { $Target = Join-Path (Get-Location) "portable-agent" }
}
New-Item -ItemType Directory -Force -Path $Target | Out-Null
$Target = (Resolve-Path $Target).Path
Write-Host "Installing into: $Target"

$GumExe = Install-Gum -Target $Target

if (-not $Components) {
    & $GumExe style --border rounded --padding "0 2" --margin "1 0" `
        --border-foreground 212 --foreground 212 "Portable Agent Toolkit - Installer"
    Write-Host "Core AI-agent stack (koboldcpp + OpenCode + Goose + RAG) is always installed."
    $selected = & $GumExe choose --no-limit `
        --header "Select optional components (space to toggle, enter to confirm):" `
        --cursor.foreground 212 --selected.foreground 212 `
        "Dev environment (C/C++, Rust, Node.js/React, Python)" `
        "Claude Code (needs your own Anthropic subscription)" `
        "Agy CLI (Antigravity CLI)"
    $Components = "core"
    if ($selected -match "Dev environment") { $Components += ",dev" }
    if ($selected -match "Claude Code") { $Components += ",claude-code" }
    if ($selected -match "Agy CLI") { $Components += ",agy-cli" }
}
Write-Host "Components: $Components"

if (-not $Models) {
    $config = Get-Content "$ScriptDir\config\models.json" -Raw | ConvertFrom-Json
    $labels = @(); $ids = @(); $defaultLabel = ""
    foreach ($m in $config.models) {
        $label = "$($m.display_name) (~$($m.size_gb)GB)"
        $labels += $label; $ids += $m.id
        if ($m.default_selected) { $defaultLabel = $label }
    }
    Write-Host "Detected system RAM: ~$(Get-TotalRamGB)GB"
    $selectedModels = & $GumExe choose --no-limit `
        --header "Select model(s) to download (space to toggle, enter to confirm):" `
        --selected $defaultLabel --cursor.foreground 212 --selected.foreground 212 `
        $labels
    $Models = ""
    for ($i = 0; $i -lt $labels.Count; $i++) {
        if ($selectedModels -contains $labels[$i]) {
            $Models += $(if ($Models) { "," } else { "" }) + $ids[$i]
        }
    }
}
Write-Host "Models: $(if ($Models) { $Models } else { 'none' })"

& powershell -NoProfile -ExecutionPolicy Bypass -File "$ScriptDir\components\core-agent-stack.ps1" -Target $Target

if ($Models) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$ScriptDir\components\models.ps1" -Target $Target -ConfigPath "$ScriptDir\config\models.json" ($Models -split ",")
}
if ($Components -match "dev") {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$ScriptDir\components\dev-environment.ps1" -Target $Target
}
if ($Components -match "claude-code") {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$ScriptDir\components\claude-code.ps1" -Target $Target
}
if ($Components -match "agy-cli") {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$ScriptDir\components\agy-cli.ps1" -Target $Target
}

Write-Host "== Deploying runtime scripts, RAG corpus, and config =="
Copy-Item "$ScriptDir\runtime\*" $Target -Recurse -Force
Copy-Item "$ScriptDir\rag" (Join-Path $Target "rag") -Recurse -Force
New-Item -ItemType Directory -Force -Path (Join-Path $Target "config") | Out-Null
Copy-Item "$ScriptDir\config\models.json" (Join-Path $Target "config\models.json") -Force

$binDir = Join-Path $Target "bin\windows"
$koboldVer = if (Test-Path (Join-Path $binDir "koboldcpp-nocuda.exe")) { try { (& (Join-Path $binDir "koboldcpp-nocuda.exe") --version 2>&1 | Select-Object -First 1) } catch { "" } } else { "" }
$opencodeVer = if (Test-Path (Join-Path $binDir "opencode.exe")) { try { (& (Join-Path $binDir "opencode.exe") --version 2>&1 | Select-Object -First 1) } catch { "" } } else { "" }
$gooseVer = if (Test-Path (Join-Path $binDir "goose.exe")) { try { (& (Join-Path $binDir "goose.exe") --version 2>&1 | Select-Object -First 1) } catch { "" } } else { "" }
$gumVer = if (Test-Path (Join-Path $binDir "gum-windows-amd64.exe")) { try { (& (Join-Path $binDir "gum-windows-amd64.exe") --version 2>&1 | Select-Object -First 1) } catch { "" } } else { "" }
$jqVer = if (Test-Path (Join-Path $binDir "jq-windows-amd64.exe")) { try { (& (Join-Path $binDir "jq-windows-amd64.exe") --version 2>&1 | Select-Object -First 1) } catch { "" } } else { "" }
$agyVer = if (Test-Path (Join-Path $binDir "agy.exe")) { try { (& (Join-Path $binDir "agy.exe") --version 2>&1 | Select-Object -First 1) } catch { "" } } else { "" }

$manifest = @{
    installed_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    versions     = @{
        koboldcpp = [string]$koboldVer
        opencode  = [string]$opencodeVer
        goose     = [string]$gooseVer
        gum       = [string]$gumVer
        jq        = [string]$jqVer
        agy       = [string]$agyVer
    }
    components   = $Components
    models       = $Models
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $Target ".versions.json")

& $GumExe style --border rounded --padding "0 2" --margin "1 0" `
    --border-foreground 212 --foreground 212 "Install complete!"
Write-Host ""
Write-Host "Installed into: $Target"
Write-Host ""
Write-Host "Run it:"
Write-Host "  cd '$Target'"
Write-Host "  .\start.bat                 # koboldcpp + pick a model + pick OpenCode/Goose"
Write-Host "  .\chat.bat                  # plain terminal chat, no orchestrator"
if ($Components -match "dev") { Write-Host "  .\dev.bat                    # enter the portable C/C++/Rust/Node/Python shell" }
if ($Components -match "claude-code") { Write-Host "  .\claude-code.bat            # real Claude Code CLI" }
if ($Components -match "agy-cli") { Write-Host "  .\agy-cli.bat                # portable Agy CLI" }
