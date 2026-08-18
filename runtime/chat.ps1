# Usage: .\chat.bat [model] [-Vulkan]
# Mirrors chat.sh. Untested on Windows.
param(
    [string]$Model = "",
    [switch]$Vulkan
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BinDir = Join-Path $ScriptDir "bin\windows"
$Port = 5001
$Log = Join-Path $ScriptDir "koboldcpp.log"

try { $PhysicalCores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum } catch { $PhysicalCores = 0 }
if (-not $PhysicalCores -or $PhysicalCores -lt 1) { $PhysicalCores = 4 }
$Threads = $PhysicalCores

$ModelsDir = Join-Path $ScriptDir "models"
$ModelPath = ""
switch ($Model) {
    "qwen2.5-coder" { $ModelPath = Join-Path $ModelsDir "qwen2.5-coder.gguf" }
    "qwen" { $ModelPath = Join-Path $ModelsDir "qwen2.5-coder.gguf" }
    "qwen3-30b" { $ModelPath = Join-Path $ModelsDir "qwen3-30b.gguf" }
    "nanbeige" { $ModelPath = Join-Path $ModelsDir "nanbeige.gguf" }
    "" { }
    default {
        $c = Join-Path $ModelsDir $Model; $cg = Join-Path $ModelsDir "$Model.gguf"
        if (Test-Path $c) { $ModelPath = $c } elseif (Test-Path $cg) { $ModelPath = $cg }
    }
}
if (-not $ModelPath) {
    $modelFiles = @(Get-ChildItem -Path $ModelsDir -Filter "*.gguf" -File -ErrorAction SilentlyContinue | Sort-Object Name)
    if ($modelFiles.Count -eq 0) { Write-Host "No .gguf files found. Run install.ps1's model step first."; exit 1 }
    elseif ($Model) { Write-Host "Unknown model '$Model'. Available: $($modelFiles.Name -join ', ')"; exit 1 }
    else { $ModelPath = $modelFiles[0].FullName; Write-Host "No model specified — using $($modelFiles[0].Name)." }
}
$Model = [System.IO.Path]::GetFileNameWithoutExtension($ModelPath)

$startedKobold = $false
$koboldProc = $null
$alreadyUp = $false
try { Invoke-RestMethod -Uri "http://127.0.0.1:$Port/v1/models" -TimeoutSec 2 | Out-Null; $alreadyUp = $true } catch {}

if ($alreadyUp) {
    Write-Host "koboldcpp already running on port $Port - reusing it."
} else {
    Write-Host "Starting koboldcpp ($Model) on port $Port ..."
    $koboldExe = Join-Path $BinDir "koboldcpp-nocuda.exe"
    $gpuArgs = @(); if ($Vulkan) { $gpuArgs = @("--usevulkan") }
    $koboldArgs = @("--model", $ModelPath, "--port", $Port, "--host", "127.0.0.1",
                    "--contextsize", "8192", "--batchsize", "2048", "--threads", $Threads) + $gpuArgs
    $koboldProc = Start-Process -FilePath $koboldExe -ArgumentList $koboldArgs `
        -RedirectStandardOutput $Log -RedirectStandardError "$Log.err" -PassThru -WindowStyle Hidden
    $startedKobold = $true
    Write-Host "Waiting for koboldcpp to come up ..."
    $ready = $false
    for ($i = 0; $i -lt 60; $i++) {
        try { Invoke-RestMethod -Uri "http://127.0.0.1:$Port/v1/models" -TimeoutSec 2 | Out-Null; $ready = $true; break }
        catch {
            if ($koboldProc.HasExited) { Write-Host "koboldcpp exited early - check $Log"; exit 1 }
            Start-Sleep -Seconds 2
        }
    }
    if (-not $ready) { Write-Host "koboldcpp did not become ready in time."; exit 1 }
    Write-Host "koboldcpp is ready."
}

$history = @()
Write-Host ""
Write-Host "Terminal chat ready. Model: $Model. Type 'exit' or 'quit' to leave."
try {
    while ($true) {
        Write-Host ""
        $line = Read-Host "You"
        if ($line -eq "exit" -or $line -eq "quit") { break }
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $history += [PSCustomObject]@{ role = "user"; content = $line }
        $body = @{ model = "local"; messages = $history; stream = $false } | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/v1/chat/completions" -Method Post -Body $body -ContentType "application/json"
        $reply = $response.choices[0].message.content
        if (-not $reply) { $reply = "[no response - check koboldcpp.log]" }
        Write-Host ""
        Write-Host "Assistant: $reply"
        $history += [PSCustomObject]@{ role = "assistant"; content = $reply }
    }
} finally {
    if ($startedKobold -and $koboldProc -and -not $koboldProc.HasExited) {
        Write-Host "Stopping koboldcpp (pid $($koboldProc.Id)) ..."
        & taskkill /PID $koboldProc.Id /T /F 2>$null | Out-Null
    }
}
