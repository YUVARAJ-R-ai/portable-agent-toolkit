# Shared helpers for install.ps1/update.ps1/components/*.ps1. Dot-source
# this, don't execute it directly: . $PSScriptRoot\..\lib\common.ps1
#
# NOTE: mirrors lib/common.sh, which is execution-verified on Linux
# (including real downloads, checksum verification, and GitHub release
# resolution). This PowerShell copy has not itself been execution-tested --
# no Windows hardware/pwsh available during development. Same standing
# caveat as the rest of this project's Windows path.

function Get-PhysicalCores {
    try {
        $n = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum
        if ($n -and $n -gt 0) { return [int]$n }
    } catch {}
    return 4
}

function Get-TotalRamGB {
    try {
        $bytes = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
        if ($bytes) { return [int]([math]::Floor($bytes / 1GB)) }
    } catch {}
    return 0
}

function Get-DownloadVerify {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Dest,
        [string]$ExpectedSha256 = ""
    )
    New-Item -ItemType Directory -Force -Path (Split-Path $Dest) | Out-Null
    Write-Host "  downloading: $(Split-Path -Leaf $Dest)"
    Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing
    if ($ExpectedSha256) {
        $actual = (Get-FileHash -Path $Dest -Algorithm SHA256).Hash.ToLower()
        if ($actual -ne $ExpectedSha256.ToLower()) {
            Write-Host "  CHECKSUM MISMATCH for $(Split-Path -Leaf $Dest)" -ForegroundColor Red
            Write-Host "    expected: $ExpectedSha256"
            Write-Host "    actual:   $actual"
            Remove-Item $Dest -Force
            exit 1
        }
        Write-Host "  checksum OK"
    }
}

function Get-LatestGithubRelease {
    param([Parameter(Mandatory)][string]$Repo)
    $resp = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -UseBasicParsing
    return $resp.tag_name
}

function Get-GithubAssetUrl {
    param([Parameter(Mandatory)][string]$Repo, [Parameter(Mandatory)][string]$Asset)
    $tag = Get-LatestGithubRelease -Repo $Repo
    return "https://github.com/$Repo/releases/download/$tag/$Asset"
}

function Install-Gum {
    param([Parameter(Mandatory)][string]$Target)
    $gumExe = Join-Path $Target "bin\windows\gum-windows-amd64.exe"
    if (Test-Path $gumExe) { return $gumExe }
    $version = "0.17.0"
    $url = "https://github.com/charmbracelet/gum/releases/download/v$version/gum_${version}_Windows_x86_64.zip"
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Invoke-WebRequest -Uri $url -OutFile (Join-Path $tmp "gum.zip") -UseBasicParsing
    Expand-Archive -Path (Join-Path $tmp "gum.zip") -DestinationPath $tmp
    New-Item -ItemType Directory -Force -Path (Split-Path $gumExe) | Out-Null
    Copy-Item (Join-Path $tmp "gum_${version}_Windows_x86_64\gum.exe") $gumExe
    Remove-Item -Recurse -Force $tmp
    return $gumExe
}
