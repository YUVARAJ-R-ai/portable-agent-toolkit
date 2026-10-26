# Usage: .\start.bat [model] [-Orchestrator opencode|goose] [-Vulkan]
param(
    [string]$Model = "",
    [switch]$Vulkan,
    [string]$Orchestrator = ""
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
$Log = Join-Path $ScriptDir "koboldcpp.log"

$ModelsDir = Join-Path $ScriptDir "models"
if (-not (Test-Path $ModelsDir)) {
    $parent = Split-Path -Parent $ScriptDir
    if (Test-Path (Join-Path $parent "models")) { $ModelsDir = Join-Path $parent "models" }
}

$GumExe = Join-Path $BinDir "gum-windows-amd64.exe"
if (-not (Test-Path $GumExe)) { $GumExe = Join-Path $BinDir "gum.exe" }
$HasGum = $false
if ($GumExe -and (Test-Path $GumExe)) {
    try { & $GumExe --version 2>&1 | Out-Null; $HasGum = $true } catch { $HasGum = $false }
}

try { $PhysicalCores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum } catch { $PhysicalCores = 0 }
if (-not $PhysicalCores -or $PhysicalCores -lt 1) { $PhysicalCores = 4 }
$Threads = $PhysicalCores

$ModelPath = ""
switch ($Model) {
    "qwen2.5-coder" { $ModelPath = Join-Path $ModelsDir "qwen2.5-coder.gguf" }
    "qwen" { $ModelPath = Join-Path $ModelsDir "qwen2.5-coder.gguf" }
    "qwen3-30b" { $ModelPath = Join-Path $ModelsDir "qwen3-30b.gguf" }
    "nanbeige" { $ModelPath = Join-Path $ModelsDir "nanbeige.gguf" }
    ""      { }
    default {
        $candidate = Join-Path $ModelsDir $Model
        $candidateGguf = Join-Path $ModelsDir "$Model.gguf"
        if (Test-Path $candidate) { $ModelPath = $candidate }
        elseif (Test-Path $candidateGguf) { $ModelPath = $candidateGguf }
    }
}

if (-not $ModelPath) {
    $modelFiles = @(Get-ChildItem -Path $ModelsDir -Filter "*.gguf" -File -ErrorAction SilentlyContinue | Sort-Object Name)
    if ($modelFiles.Count -eq 0) {
        Write-Host "No .gguf files found in $ModelsDir. Run install.ps1's model step first." -ForegroundColor Red
        exit 1
    } elseif ($Model) {
        Write-Host "Unknown model '$Model'. Available: $($modelFiles.Name -join ', ')" -ForegroundColor Red
        exit 1
    } elseif ($modelFiles.Count -eq 1) {
        $ModelPath = $modelFiles[0].FullName
    } else {
        if ($HasGum) {
            $picked = & $GumExe choose ($modelFiles | ForEach-Object { $_.Name }) `
                --header "Pick a model to load:" --cursor.foreground 212 --selected.foreground 212
            if (-not $picked) { Write-Host "No model selected - exiting."; exit 1 }
            $ModelPath = Join-Path $ModelsDir $picked
        } else {
            Write-Host "Available models:"
            for ($i = 0; $i -lt $modelFiles.Count; $i++) {
                Write-Host "  $($i + 1). $($modelFiles[$i].Name)"
            }
            $pickedNum = Read-Host "Select model number [1]"
            if (-not $pickedNum) { $pickedNum = "1" }
            $idx = [int]$pickedNum - 1
            if ($idx -ge 0 -and $idx -lt $modelFiles.Count) {
                $ModelPath = $modelFiles[$idx].FullName
            } else {
                $ModelPath = $modelFiles[0].FullName
            }
        }
    }
}
$ApiModelName = [System.IO.Path]::GetFileNameWithoutExtension($ModelPath)
$Model = $ApiModelName

$startedKobold = $false
$koboldProc = $null
$alreadyUp = $false
try { Invoke-RestMethod -Uri "http://127.0.0.1:$Port/v1/models" -TimeoutSec 2 | Out-Null; $alreadyUp = $true } catch {}

if ($alreadyUp) {
    Write-Host "koboldcpp already running on port $Port - reusing it."
} else {
    Write-Host "Starting koboldcpp ($Model) on port $Port ..."
    $koboldExe = Join-Path $BinDir "koboldcpp-nocuda.exe"
    if (-not (Test-Path $koboldExe)) { $koboldExe = Join-Path $BinDir "koboldcpp.exe" }
    if (-not (Test-Path $koboldExe)) {
        Write-Host "koboldcpp executable not found in $BinDir" -ForegroundColor Red
        exit 1
    }
    $gpuArgs = @()
    if ($Vulkan) { $gpuArgs = @("--usevulkan") }
    $koboldArgs = @("--model", "`"$ModelPath`"", "--port", "$Port", "--host", "127.0.0.1",
                    "--contextsize", "16384", "--batchsize", "2048",
                    "--threads", "$Threads", "--admin", "--admindir", "`"$ModelsDir`"") + $gpuArgs
    $koboldProc = Start-Process -FilePath $koboldExe -ArgumentList $koboldArgs `
        -RedirectStandardOutput $Log -RedirectStandardError "$Log.err" -PassThru -WindowStyle Hidden
    $startedKobold = $true

    Write-Host "Waiting for koboldcpp to come up ..."
    $ready = $false
    for ($i = 0; $i -lt 60; $i++) {
        try {
            Invoke-RestMethod -Uri "http://127.0.0.1:$Port/v1/models" -TimeoutSec 2 | Out-Null
            $ready = $true; break
        } catch {
            if ($koboldProc.HasExited) {
                Write-Host "koboldcpp exited early - check $Log and $Log.err" -ForegroundColor Red
                Get-Content $Log -ErrorAction SilentlyContinue
                Get-Content "$Log.err" -ErrorAction SilentlyContinue
                exit 1
            }
            Start-Sleep -Seconds 2
        }
    }
    if (-not $ready) { Write-Host "koboldcpp did not become ready in time." -ForegroundColor Red; exit 1 }
    Write-Host "koboldcpp is ready." -ForegroundColor Green
}

$GooseExe = Join-Path $BinDir "goose.exe"
$OpencodeExe = Join-Path $BinDir "opencode.exe"

if (-not $Orchestrator) {
    if ($HasGum) {
        & $GumExe style --border rounded --padding "0 2" --margin "1 0" `
            --border-foreground 212 --foreground 212 "Portable Agent Toolkit  .  model: $Model"
        $Orchestrator = & $GumExe choose "OpenCode" "Goose" `
            --header "Pick a coding-agent orchestrator:" --cursor.foreground 212 --selected.foreground 212
    } else {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Portable Agent Toolkit  .  model: $Model" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Pick a coding-agent orchestrator:"
        Write-Host "  1. OpenCode"
        Write-Host "  2. Goose"
        $pick = Read-Host "Select [1]"
        if ($pick -eq "2" -or $pick -like "*goose*") { $Orchestrator = "Goose" } else { $Orchestrator = "OpenCode" }
    }
}
if (-not $Orchestrator) {
    Write-Host "No orchestrator selected - exiting."
    if ($startedKobold -and $koboldProc -and -not $koboldProc.HasExited) {
        & taskkill /PID $koboldProc.Id /T /F 2>&1 | Out-Null
    }
    exit 1
}

$DevDir = Join-Path $ScriptDir "dev"
if (-not (Test-Path $DevDir)) {
    $parent = Split-Path -Parent $ScriptDir
    if (Test-Path (Join-Path $parent "dev")) { $DevDir = Join-Path $parent "dev" }
}
if (Test-Path $DevDir) {
    $env:Path = "$DevDir\zig;$DevDir\rust\bin;$DevDir\node;$DevDir\python;$DevDir\python\Scripts;$env:Path"
    $env:CARGO_HOME = Join-Path $DevDir "rust"
    $env:RUSTUP_HOME = Join-Path $DevDir "rust"
    $env:npm_config_cache = Join-Path $DevDir "node\cache"
    $env:PIP_CACHE_DIR = Join-Path $DevDir "python\cache"
}

$wsDir = Join-Path $ScriptDir "workspace"
if (-not (Test-Path $wsDir)) {
    $parent = Split-Path -Parent $ScriptDir
    if (Test-Path (Join-Path $parent "workspace")) { $wsDir = Join-Path $parent "workspace" }
    else { New-Item -ItemType Directory -Force -Path $wsDir | Out-Null }
}

$ocConfig = Join-Path $wsDir "opencode.json"
if (Test-Path $ocConfig) {
    try {
        $json = Get-Content $ocConfig -Raw | ConvertFrom-Json
        $modelsMap = @{}
        Get-ChildItem -Path $ModelsDir -Filter "*.gguf" -File -ErrorAction SilentlyContinue | ForEach-Object {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            $modelsMap[$baseName] = @{ name = $baseName }
        }
        # Add-Member: the template has no "model" key, and plain assignment of a new property throws.
        $json | Add-Member -NotePropertyName model -NotePropertyValue "local/$ApiModelName" -Force
        $json.provider.local.models = $modelsMap
        $jsonStr = $json | ConvertTo-Json -Depth 5
        # Write UTF-8 without BOM so CLI json parsers on Windows don't choke on BOM bytes
        [System.IO.File]::WriteAllText($ocConfig, $jsonStr, (New-Object System.Text.UTF8Encoding $false))
    } catch {}
}

$gooseConfigDir = Join-Path $ScriptDir "goose-config"
if (-not (Test-Path $gooseConfigDir)) {
    $parent = Split-Path -Parent $ScriptDir
    if (Test-Path (Join-Path $parent "goose-config")) { $gooseConfigDir = Join-Path $parent "goose-config" }
    else { New-Item -ItemType Directory -Force -Path $gooseConfigDir | Out-Null }
}

try {
    Set-Location $wsDir
    switch ($Orchestrator.ToLower()) {
        "opencode" {
            # Keep the host's ~/.claude/CLAUDE.md + skills out of the prompt (they overflow the 16K context).
            $env:OPENCODE_DISABLE_CLAUDE_CODE = "1"
            $env:OPENCODE_DISABLE_EXTERNAL_SKILLS = "1"
            $env:XDG_CONFIG_HOME = Join-Path $ScriptDir "opencode-config"
            $env:XDG_DATA_HOME = Join-Path $ScriptDir "opencode-data"
            & $OpencodeExe --model "local/$ApiModelName"
        }
        "goose" {
            $env:APPDATA = $gooseConfigDir
            $env:OPENAI_BASE_URL = "http://127.0.0.1:$Port/v1"
            $env:OPENAI_API_KEY = "not-needed"
            $env:GOOSE_TELEMETRY_OFF = "1"
            $env:GOOSE_DISABLE_KEYRING = "1"
            $env:GOOSE_DISABLE_SESSION_NAMING = "1"
            & $GooseExe session --no-profile --with-builtin developer --provider openai --model $ApiModelName
        }
        default { Write-Host "Unknown orchestrator '$Orchestrator'." }
    }
} finally {
    if ($startedKobold -and $koboldProc -and -not $koboldProc.HasExited) {
        Write-Host "Stopping koboldcpp (pid $($koboldProc.Id)) ..."
        & taskkill /PID $koboldProc.Id /T /F 2>&1 | Out-Null
    }
}
