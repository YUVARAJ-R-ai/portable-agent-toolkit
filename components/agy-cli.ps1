# Usage: .\agy-cli.ps1 <target_dir>
# Setup the portable Agy (Antigravity) CLI into <target_dir>\bin\windows\agy.exe
param([Parameter(Mandatory)][string]$Target)

. "$PSScriptRoot\..\lib\common.ps1"

Write-Host "== Agy CLI =="
$binDir = Join-Path $Target "bin\windows"
$agyHome = Join-Path $Target "agy-cli\home"
$agyWorkspace = Join-Path $Target "agy-cli\workspace"
New-Item -ItemType Directory -Force -Path $binDir, $agyHome, $agyWorkspace | Out-Null

$agyCmd = Get-Command "agy" -ErrorAction SilentlyContinue
if (-not $agyCmd) { $agyCmd = Get-Command "agy.exe" -ErrorAction SilentlyContinue }

if ($agyCmd) {
    $agyPath = $agyCmd.Source
    Copy-Item $agyPath (Join-Path $binDir "agy.exe") -Force
    Write-Host "  agy-cli: Copied from host ($agyPath)"
} else {
    Write-Host "  agy-cli: WARNING: 'agy' executable not found on host. Place agy.exe into $binDir manually." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Agy CLI setup complete."
