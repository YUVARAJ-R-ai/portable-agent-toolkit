# Usage: .\models.ps1 <target_dir> <config\models.json path> <model_id> [model_id...]
# Mirrors components/models.sh. Untested (no Windows hardware available).
param(
    [Parameter(Mandatory)][string]$Target,
    [Parameter(Mandatory)][string]$ConfigPath,
    [Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$ModelIds
)
. "$PSScriptRoot\..\lib\common.ps1"

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path (Join-Path $Target "models") | Out-Null

$cleanModelIds = @()
foreach ($m in $ModelIds) {
    if ($m) {
        $cleanModelIds += ($m -split ",")
    }
}

foreach ($id in $cleanModelIds) {
    $id = $id.Trim()
    if (-not $id) { continue }
    $entry = $config.models | Where-Object { $_.id -eq $id }
    if (-not $entry) { Write-Host "Unknown model id '$id'" -ForegroundColor Red; exit 1 }

    $dest = Join-Path $Target "models\$id.gguf"
    if (Test-Path $dest) { Write-Host "Already downloaded: $($entry.display_name) -- skipping."; continue }

    if ($entry.ram_warning_gb -and $entry.ram_warning_gb -gt 0) {
        $ram = Get-TotalRamGB
        if ($ram -gt 0 -and $ram -lt $entry.ram_warning_gb) {
            Write-Host "WARNING: $($entry.display_name) needs ~$($entry.ram_warning_gb)GB+ RAM; this machine has ~${ram}GB." -ForegroundColor Yellow
            Write-Host "         Downloading anyway ($($entry.size_gb)GB) -- Ctrl+C to skip." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        }
    }

    Write-Host "Downloading $($entry.display_name) (~$($entry.size_gb)GB) from $($entry.repo) ..."
    $url = "https://huggingface.co/$($entry.repo)/resolve/main/$($entry.file)?download=true"
    Get-DownloadVerify -Url $url -Dest $dest
    Write-Host "  saved as models\$id.gguf"
}
Write-Host "Model download step complete."
