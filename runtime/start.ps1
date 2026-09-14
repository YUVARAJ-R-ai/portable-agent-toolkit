# Usage: .\start.bat [model] [-Orchestrator opencode|goose] [-Vulkan]
# Mirrors start.sh (execution-verified on Linux). Untested on Windows.
param(
    [string]$Model = "",
    [switch]$Vulkan,
    [string]$Orchestrator = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BinDir = Join-Path $ScriptDir "bin\windows"
$Port = 5001
$Log = Join-Path $ScriptDir "koboldcpp.log"
$ModelsDir = Join-Path $ScriptDir "models"
$GumExe = Join-Path $BinDir "gum-windows-amd64.exe"

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
        Write-Host "No .gguf files found in $ModelsDir. Run install.ps1's model step first."
        exit 1
    } elseif ($Model) {
        Write-Host "Unknown model '$Model'. Available: $($modelFiles.Name -join ', ')"
        exit 1
    } elseif ($modelFiles.Count -eq 1) {
        $ModelPath = $modelFiles[0].FullName
    } else {
        $picked = & $GumExe choose ($modelFiles | ForEach-Object { $_.Name }) `
            --header "Pick a model to load:" --cursor.foreground 212 --selected.foreground 212
        if (-not $picked) { Write-Host "No model selected — exiting."; exit 1 }
        $ModelPath = Join-Path $ModelsDir $picked
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
    $gpuArgs = @()
    if ($Vulkan) { $gpuArgs = @("--usevulkan") }
    $koboldArgs = @("--model", $ModelPath, "--port", $Port, "--host", "127.0.0.1",
                    "--contextsize", "16384", "--batchsize", "2048",
                    "--threads", $Threads, "--admin", "--admindir", $ModelsDir) + $gpuArgs
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
                Write-Host "koboldcpp exited early - check $Log and $Log.err"
                Get-Content $Log -ErrorAction SilentlyContinue
                Get-Content "$Log.err" -ErrorAction SilentlyContinue
                exit 1
            }
            Start-Sleep -Seconds 2
        }
    }
    if (-not $ready) { Write-Host "koboldcpp did not become ready in time."; exit 1 }
    Write-Host "koboldcpp is ready."
}

$GooseExe = Join-Path $BinDir "goose.exe"
if (-not $Orchestrator) {
    & $GumExe style --border rounded --padding "0 2" --margin "1 0" `
        --border-foreground 212 --foreground 212 "Portable Agent Toolkit  .  model: $Model"
    $Orchestrator = & $GumExe choose "OpenCode" "Goose" `
        --header "Pick a coding-agent orchestrator:" --cursor.foreground 212 --selected.foreground 212
}
if (-not $Orchestrator) {
    Write-Host "No orchestrator selected - exiting."
    if ($startedKobold -and $koboldProc -and -not $koboldProc.HasExited) {
        & taskkill /PID $koboldProc.Id /T /F 2>&1 | Out-Null
    }
    exit 1
}

$DevDir = Join-Path $ScriptDir "dev"
if (Test-Path $DevDir) {
    $env:Path = "$DevDir\zig;$DevDir\rust\bin;$DevDir\node;$DevDir\python;$env:Path"
    $env:CARGO_HOME = Join-Path $DevDir "rust"
    $env:RUSTUP_HOME = Join-Path $DevDir "rust"
    $env:npm_config_cache = Join-Path $DevDir "node\cache"
    $env:PIP_CACHE_DIR = Join-Path $DevDir "python\cache"
}

$wsDir = Join-Path $ScriptDir "workspace"
$ocConfig = Join-Path $wsDir "opencode.json"
if (Test-Path $ocConfig) {
    try {
        $json = Get-Content $ocConfig -Raw | ConvertFrom-Json
        $modelsMap = @{}
        Get-ChildItem -Path $ModelsDir -Filter "*.gguf" -File -ErrorAction SilentlyContinue | ForEach-Object {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            $modelsMap[$baseName] = @{ name = $baseName }
        }
        $json.model = "local/$ApiModelName"
        $json.provider.local.models = $modelsMap
        $json | ConvertTo-Json -Depth 5 | Set-Content $ocConfig
    } catch {}
}

try {
    Set-Location $wsDir
    switch ($Orchestrator.ToLower()) {
        "opencode" {
            $env:XDG_CONFIG_HOME = Join-Path $ScriptDir "opencode-config"
            $env:XDG_DATA_HOME = Join-Path $ScriptDir "opencode-data"
            & (Join-Path $BinDir "opencode.exe") --model "local/$ApiModelName"
        }
        "goose" {
            $env:APPDATA = Join-Path $ScriptDir "goose-config"
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
