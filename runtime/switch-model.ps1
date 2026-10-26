# Usage: .\switch-model.bat [-List] [ModelFilename]
param(
    [switch]$List,
    [switch]$l,
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$TargetParts
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$BinDir = Join-Path $ScriptDir "bin\windows"
if (-not (Test-Path $BinDir)) { $BinDir = Join-Path $ScriptDir "bin" }
if (-not (Test-Path $BinDir)) {
    $parent = Split-Path -Parent $ScriptDir
    if (Test-Path (Join-Path $parent "bin\windows")) { $BinDir = Join-Path $parent "bin\windows" }
    elseif (Test-Path (Join-Path $parent "bin")) { $BinDir = Join-Path $parent "bin" }
}

$Port = 5001
$Base = "http://127.0.0.1:$Port"
$GumExe = Join-Path $BinDir "gum-windows-amd64.exe"
if (-not (Test-Path $GumExe)) { $GumExe = Join-Path $BinDir "gum.exe" }
$HasGum = $false
if ($GumExe -and (Test-Path $GumExe)) {
    try { & $GumExe --version 2>&1 | Out-Null; $HasGum = $true } catch { $HasGum = $false }
}

try { Invoke-RestMethod -Uri "$Base/v1/models" -TimeoutSec 2 | Out-Null } catch {
    Write-Host "koboldcpp isn't running on port $Port. Start it first with: .\start.bat"
    exit 1
}

$options = @()
try { $options = @(Invoke-RestMethod -Uri "$Base/api/admin/list_options" -TimeoutSec 5) } catch {}
if ($options.Count -eq 0) {
    Write-Host "No admin options returned by koboldcpp. It needs -admin -admindir (start.ps1 does this automatically)."
    exit 1
}

$Target = ""
if ($TargetParts) { $Target = ($TargetParts -join " ").Trim() }

$isList = $List -or $l -or ($Target -eq "--list") -or ($Target -eq "-list") -or ($Target -eq "/list") -or ($Target -eq "-l")
if ($isList) { $options | ForEach-Object { Write-Host $_ }; exit 0 }

if (-not $Target) {
    if ($HasGum) {
        $Target = & $GumExe choose $options --header "Switch koboldcpp to:" `
            --cursor.foreground 212 --selected.foreground 212
    } else {
        Write-Host "Available models to switch to:"
        for ($i = 0; $i -lt $options.Count; $i++) {
            Write-Host "  $($i + 1). $($options[$i])"
        }
        $picked = Read-Host "Select number [1]"
        if (-not $picked) { $picked = "1" }
        $idx = [int]$picked - 1
        if ($idx -ge 0 -and $idx -lt $options.Count) {
            $Target = $options[$idx]
        }
    }
}
if (-not $Target) { Write-Host "No model selected - nothing changed."; exit 1 }
if ($options -notcontains $Target) {
    Write-Host "'$Target' isn't one of the available options:"
    $options | ForEach-Object { Write-Host "  $_" }
    exit 1
}

$oldId = ""
try { $oldId = (Invoke-RestMethod -Uri "$Base/v1/models" -TimeoutSec 2).data[0].id } catch {}

Write-Host "Requesting swap to '$Target' ..."
$body = @{ filename = $Target } | ConvertTo-Json -Compress
$swapResp = Invoke-RestMethod -Uri "$Base/api/admin/reload_config" -Method Post -ContentType "application/json" -Body $body
if (-not $swapResp.success) {
    Write-Host "koboldcpp rejected the swap request: $($swapResp | ConvertTo-Json -Compress)"
    exit 1
}

if ($Target -eq "unload_model") {
    Write-Host -NoNewline "Waiting for koboldcpp to unload the model "
    for ($i = 0; $i -lt 30; $i++) {
        $curId = ""
        try { $curId = (Invoke-RestMethod -Uri "$Base/v1/models" -TimeoutSec 2).data[0].id } catch {}
        if (-not $curId) { Write-Host ""; Write-Host "Model unloaded."; exit 0 }
        Write-Host -NoNewline "."; Start-Sleep -Seconds 1
    }
    Write-Host ""; Write-Host "Timed out waiting for the unload."; exit 1
}

Write-Host -NoNewline "Waiting for koboldcpp to come back up with the new model "
for ($i = 0; $i -lt 90; $i++) {
    $curId = ""
    try { $curId = (Invoke-RestMethod -Uri "$Base/v1/models" -TimeoutSec 2).data[0].id } catch {}
    if ($curId -and $curId -ne $oldId) { Write-Host ""; Write-Host "Now serving: $curId"; exit 0 }
    Write-Host -NoNewline "."; Start-Sleep -Seconds 1
}
Write-Host ""; Write-Host "Timed out waiting for koboldcpp to report a different model."
exit 1
