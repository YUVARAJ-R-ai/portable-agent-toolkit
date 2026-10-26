# Usage: .\chat.bat [model] [-Vulkan]
# Terminal chat with the local model featuring real-time SSE token streaming,
# styled ANSI/PowerShell interface, and interactive slash commands.
param(
    [string]$Model = "",
    [switch]$Vulkan
)

# Required on Windows PowerShell 5.1 to ensure HttpClient and HttpRequestMessage types are available
try { Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue } catch {}
# Keep this file pure ASCII: powershell.exe 5.1 reads BOM-less scripts as ANSI, so UTF-8 glyphs break parsing.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$BinDir = Join-Path $ScriptDir "bin\windows"
if (-not (Test-Path $BinDir)) { $BinDir = Join-Path $ScriptDir "bin" }
if (-not (Test-Path $BinDir)) {
    $parent = Split-Path -Parent $ScriptDir
    if (Test-Path (Join-Path $parent "bin\windows")) { $BinDir = Join-Path $parent "bin\windows" }
    elseif (Test-Path (Join-Path $parent "bin")) { $BinDir = Join-Path $parent "bin" }
}

$Port = 5001
$Log = Join-Path $ScriptDir "koboldcpp.log"

try { $PhysicalCores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum } catch { $PhysicalCores = 0 }
if (-not $PhysicalCores -or $PhysicalCores -lt 1) { $PhysicalCores = 4 }
$Threads = $PhysicalCores

$ModelsDir = Join-Path $ScriptDir "models"
if (-not (Test-Path $ModelsDir)) {
    $parent = Split-Path -Parent $ScriptDir
    if (Test-Path (Join-Path $parent "models")) { $ModelsDir = Join-Path $parent "models" }
}

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
    if ($modelFiles.Count -eq 0) { Write-Host "No .gguf files found. Run install.ps1's model step first." -ForegroundColor Red; exit 1 }
    elseif ($Model) { Write-Host "Unknown model '$Model'. Available: $($modelFiles.Name -join ', ')" -ForegroundColor Red; exit 1 }
    else { $ModelPath = $modelFiles[0].FullName }
}
$Model = [System.IO.Path]::GetFileNameWithoutExtension($ModelPath)

$startedKobold = $false
$koboldProc = $null
$alreadyUp = $false
try { Invoke-RestMethod -Uri "http://127.0.0.1:$Port/v1/models" -TimeoutSec 2 | Out-Null; $alreadyUp = $true } catch {}

if ($alreadyUp) {
    Write-Host "koboldcpp already running on port $Port - connected." -ForegroundColor DarkGray
} else {
    Write-Host "Starting koboldcpp ($Model) on port $Port ..." -ForegroundColor DarkGray
    $koboldExe = Join-Path $BinDir "koboldcpp-nocuda.exe"
    if (-not (Test-Path $koboldExe)) { $koboldExe = Join-Path $BinDir "koboldcpp.exe" }
    if (-not (Test-Path $koboldExe)) {
        Write-Host "koboldcpp executable not found in $BinDir" -ForegroundColor Red
        exit 1
    }
    $gpuArgs = @(); if ($Vulkan) { $gpuArgs = @("--usevulkan") }
    $koboldArgs = @("--model", "`"$ModelPath`"", "--port", "$Port", "--host", "127.0.0.1",
                    "--contextsize", "8192", "--batchsize", "2048", "--threads", "$Threads") + $gpuArgs
    $koboldProc = Start-Process -FilePath $koboldExe -ArgumentList $koboldArgs `
        -RedirectStandardOutput $Log -RedirectStandardError "$Log.err" -PassThru -WindowStyle Hidden
    $startedKobold = $true
    Write-Host "Waiting for model to load into memory..." -NoNewline -ForegroundColor DarkGray
    $ready = $false
    for ($i = 0; $i -lt 60; $i++) {
        try { Invoke-RestMethod -Uri "http://127.0.0.1:$Port/v1/models" -TimeoutSec 2 | Out-Null; $ready = $true; break }
        catch {
            if ($koboldProc.HasExited) { Write-Host "`nkoboldcpp exited early - check $Log" -ForegroundColor Red; exit 1 }
            Write-Host "." -NoNewline -ForegroundColor DarkGray
            Start-Sleep -Seconds 2
        }
    }
    if (-not $ready) { Write-Host "`nkoboldcpp did not become ready in time." -ForegroundColor Red; exit 1 }
    Write-Host " ready!" -ForegroundColor Green
}

Write-Host ""
Write-Host "+-------------------------------------------------------------+" -ForegroundColor DarkGray
Write-Host "|  Portable Agent Toolkit - Streaming Terminal Chat          |" -ForegroundColor DarkGray
Write-Host "|  Model:   $Model" -ForegroundColor Cyan
Write-Host "|  Server:  http://127.0.0.1:$Port (koboldcpp)" -ForegroundColor Green
Write-Host "|  Threads: $Threads cores | Context: 8192 tokens | Stream: ON" -ForegroundColor Yellow
Write-Host "|" -ForegroundColor DarkGray
Write-Host "|  Commands: /clear (reset) | /model (info) | /exit (quit)    |" -ForegroundColor DarkGray
Write-Host "+-------------------------------------------------------------+" -ForegroundColor DarkGray

$history = @()
try {
    while ($true) {
        Write-Host ""
        Write-Host "> You: " -NoNewline -ForegroundColor Cyan
        $line = Read-Host
        if ($null -eq $line) { break }
        $line = $line.Trim()

        if ($line -eq "exit" -or $line -eq "quit" -or $line -eq "/exit" -or $line -eq "/quit" -or $line -eq "/q") {
            Write-Host "Goodbye!" -ForegroundColor DarkGray
            break
        }
        if ($line -eq "/clear" -or $line -eq "/reset") {
            $history = @()
            Write-Host "Conversation history cleared." -ForegroundColor Green
            continue
        }
        if ($line -eq "/model" -or $line -eq "/info") {
            Write-Host "Model File:    $ModelPath" -ForegroundColor DarkGray
            Write-Host "Active Server: http://127.0.0.1:$Port" -ForegroundColor DarkGray
            Write-Host "Threads:       $Threads cores" -ForegroundColor DarkGray
            Write-Host "History Turns: $($history.Count)" -ForegroundColor DarkGray
            continue
        }
        if ($line -eq "/help") {
            Write-Host "Available Commands:" -ForegroundColor White
            Write-Host "  /clear      Reset conversation context" -ForegroundColor Cyan
            Write-Host "  /model      Show active model info" -ForegroundColor Cyan
            Write-Host "  /exit, quit Exit chat session" -ForegroundColor Cyan
            continue
        }
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $history += [PSCustomObject]@{ role = "user"; content = $line }
        if ($history.Count -gt 20) {
            $history = $history[-20..-1]
        }

        Write-Host ""
        Write-Host "* Assistant: " -NoNewline -ForegroundColor Magenta

        $body = @{ model = "local"; messages = $history; stream = $true } | ConvertTo-Json -Depth 10

        $reply = ""
        try {
            $client = [System.Net.Http.HttpClient]::new()
            $request = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Post, "http://127.0.0.1:$Port/v1/chat/completions")
            $request.Content = [System.Net.Http.StringContent]::new($body, [System.Text.Encoding]::UTF8, "application/json")
            $response = $client.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
            $stream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
            $reader = [System.IO.StreamReader]::new($stream)

            while (-not $reader.EndOfStream) {
                $streamLine = $reader.ReadLine()
                if ($null -ne $streamLine -and $streamLine.StartsWith("data: ") -and $streamLine -ne "data: [DONE]") {
                    $jsonStr = $streamLine.Substring(6)
                    try {
                        $chunk = $jsonStr | ConvertFrom-Json
                        $token = $chunk.choices[0].delta.content
                        if ($token) {
                            Write-Host -NoNewline $token
                            $reply += $token
                        }
                    } catch {}
                }
            }
            $reader.Close()
            $client.Dispose()
        } catch {
            Write-Host "`n[Error communicating with server: $_]" -ForegroundColor Red
        }

        Write-Host ""
        if ($reply) {
            $history += [PSCustomObject]@{ role = "assistant"; content = $reply }
        }
        Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray
    }
} finally {
    if ($startedKobold -and $koboldProc -and -not $koboldProc.HasExited) {
        Write-Host "`nStopping koboldcpp (pid $($koboldProc.Id)) ..." -ForegroundColor DarkGray
        & taskkill /PID $koboldProc.Id /T /F 2>&1 | Out-Null
    }
}
