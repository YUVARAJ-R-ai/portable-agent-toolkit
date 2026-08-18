# Usage: .\claude-code.ps1 <target_dir>
# Mirrors components/claude-code.sh. Untested (no Windows hardware available).
param([Parameter(Mandatory)][string]$Target)
. "$PSScriptRoot\..\lib\common.ps1"

Write-Host "== Claude Code CLI =="
$version = (Invoke-WebRequest -Uri "https://downloads.claude.ai/claude-code-releases/latest" -UseBasicParsing).Content.Trim()
Write-Host "  version $version"
$manifest = Invoke-RestMethod -Uri "https://downloads.claude.ai/claude-code-releases/$version/manifest.json" -UseBasicParsing
$platform = "win32-x64"
$sha = $manifest.platforms.$platform.checksum

$binDir = Join-Path $Target "bin\windows"
New-Item -ItemType Directory -Force -Path $binDir, (Join-Path $Target "claude-code\config"), (Join-Path $Target "claude-code\workspace") | Out-Null
$url = "https://downloads.claude.ai/claude-code-releases/$version/$platform/claude.exe"
Get-DownloadVerify -Url $url -Dest (Join-Path $binDir "claude-code.exe") -ExpectedSha256 $sha

Write-Host ""
Write-Host "Claude Code binary installed. One-time step YOU must do:"
Write-Host "  1. Run: $(Join-Path $binDir 'claude-code.exe') setup-token"
Write-Host "  2. Approve access in the browser tab that opens."
Write-Host "  3. Save the printed token as the ONLY content of:"
Write-Host "       $(Join-Path $Target 'claude-code\token.txt')"
Write-Host "See docs\claude-code.md for the full explanation and security tradeoffs."
