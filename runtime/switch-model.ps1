# Usage: .\switch-model.bat [-List] [ModelFilename]
# Mirrors switch-model.sh (execution-verified on Linux, including a real
# fix for a swap-completion timing race). Untested on Windows.
param(
    [switch]$List,
    [string]$Target = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BinDir = Join-Path $ScriptDir "bin\windows"
$Port = 5001
$Base = "http://127.0.0.1:$Port"
$GumExe = Join-Path $BinDir "gum-windows-amd64.exe"

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
if ($List) { $options | ForEach-Object { Write-Host $_ }; exit 0 }

if (-not $Target) {
    $Target = & $GumExe choose $options --header "Switch koboldcpp to:" `
        --cursor.foreground 212 --selected.foreground 212
}
if (-not $Target) { Write-Host "No model selected — nothing changed."; exit 1 }
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
