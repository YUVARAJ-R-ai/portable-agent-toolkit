# Usage: .\agy-cli.bat [-Workspace <dir>] [agy args...]
param(
    [string]$Workspace = "",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$AgyArgs
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$AgyBin = Join-Path $ScriptDir "bin\windows\agy.exe"
if (-not (Test-Path $AgyBin)) { $AgyBin = Join-Path $ScriptDir "bin\agy.exe" }
if (-not (Test-Path $AgyBin)) {
    $parent = Split-Path -Parent $ScriptDir
    if (Test-Path (Join-Path $parent "bin\windows\agy.exe")) { $AgyBin = Join-Path $parent "bin\windows\agy.exe" }
    elseif (Test-Path (Join-Path $parent "bin\agy.exe")) { $AgyBin = Join-Path $parent "bin\agy.exe" }
}

$AgyDir = Join-Path $ScriptDir "agy-cli"
if (-not (Test-Path $AgyDir)) {
    $parent = Split-Path -Parent $ScriptDir
    if (Test-Path (Join-Path $parent "agy-cli")) { $AgyDir = Join-Path $parent "agy-cli" }
}

if (-not (Test-Path $AgyBin)) {
    Write-Host "Agy CLI isn't installed. Run install.bat with the Agy CLI component or place agy.exe into bin\windows\." -ForegroundColor Red
    exit 1
}

$homeDir = Join-Path $AgyDir "home"
New-Item -ItemType Directory -Force -Path $homeDir | Out-Null
$env:HOME = $homeDir
$env:USERPROFILE = $homeDir

$targetWorkspace = if ($Workspace) { $Workspace } else { Join-Path $AgyDir "workspace" }
New-Item -ItemType Directory -Force -Path $targetWorkspace | Out-Null
Set-Location $targetWorkspace

& $AgyBin @AgyArgs
