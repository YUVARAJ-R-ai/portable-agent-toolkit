# Usage: .\claude-code.bat [-SkipPermissions] [claude args...]
# Mirrors claude-code.sh. Untested on Windows.
param(
    [switch]$SkipPermissions,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ClaudeArgs
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeExe = Join-Path $ScriptDir "bin\windows\claude-code.exe"
$CcDir = Join-Path $ScriptDir "claude-code"
$TokenFile = Join-Path $CcDir "token.txt"

if (-not (Test-Path $ClaudeExe)) {
    Write-Host "Claude Code isn't installed. Run install.ps1 with the Claude Code component selected first."
    exit 1
}

$tokenValue = ""
if (Test-Path $TokenFile) { $tokenValue = (Get-Content $TokenFile -Raw).Trim() }
if ($tokenValue.Length -eq 0) {
    Write-Host "No auth token found at:"
    Write-Host "  $TokenFile"
    Write-Host ""
    Write-Host "One-time setup (do this once, anywhere you have a browser):"
    Write-Host "  1. Run:  `"$ClaudeExe`" setup-token"
    Write-Host "  2. Approve access in the browser that opens."
    Write-Host "  3. Copy the token it prints and save it as the ONLY content of:"
    Write-Host "       $TokenFile"
    Write-Host ""
    Write-Host "See docs\claude-code.md for the security tradeoff and how to revoke it."
    exit 1
}

$env:CLAUDE_CODE_OAUTH_TOKEN = $tokenValue
$env:CLAUDE_CONFIG_DIR = Join-Path $CcDir "config"

$finalArgs = @()
if ($SkipPermissions) {
    Write-Host "WARNING: launching with --dangerously-skip-permissions - every tool call runs with NO confirmation." -ForegroundColor Yellow
    $finalArgs += "--dangerously-skip-permissions"
}
if ($ClaudeArgs) { $finalArgs += $ClaudeArgs }

Write-Host "Checking connectivity to Anthropic's API ..."
try {
    Invoke-WebRequest -Uri "https://api.anthropic.com" -Method Head -TimeoutSec 8 -UseBasicParsing | Out-Null
} catch {
    Write-Host "Could not reach api.anthropic.com within 8s. If claude-code then"
    Write-Host "appears to hang with no output, check this machine's internet/VPN/proxy/firewall first."
}

Write-Host "Launching claude-code.exe now ..."
New-Item -ItemType Directory -Force -Path (Join-Path $CcDir "workspace") | Out-Null
Set-Location (Join-Path $CcDir "workspace")
& $ClaudeExe @finalArgs
