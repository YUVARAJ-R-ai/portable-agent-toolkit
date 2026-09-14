# Usage: .\agy-cli.bat [-Workspace <dir>] [agy args...]
param(
    [string]$Workspace = "",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$AgyArgs
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AgyBin = Join-Path $ScriptDir "bin\windows\agy.exe"
if (-not (Test-Path $AgyBin)) {
    $AgyBin = Join-Path $ScriptDir "bin\agy.exe"
}
$AgyDir = Join-Path $ScriptDir "agy-cli"

if (-not (Test-Path $AgyBin)) {
    Write-Host "Agy CLI isn't installed. Run install.bat with the Agy CLI component or place agy.exe into bin\windows\." -ForegroundColor Red
    exit 1
}

$env:HOME = Join-Path $AgyDir "home"
$env:USERPROFILE = Join-Path $AgyDir "home"

$targetWorkspace = if ($Workspace) { $Workspace } else { Join-Path $AgyDir "workspace" }
New-Item -ItemType Directory -Force -Path $targetWorkspace | Out-Null
Set-Location $targetWorkspace

& $AgyBin @AgyArgs
