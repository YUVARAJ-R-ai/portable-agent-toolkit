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
    $destDir = Split-Path $Dest
    if ($destDir) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
    Write-Host "  downloading: $(Split-Path -Leaf $Dest)"
    $oldPref = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing -Headers @{ "User-Agent" = "PortableAgentToolkit" }
    } finally {
        $ProgressPreference = $oldPref
    }
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
    if ($Repo -eq "sst/opencode") { $Repo = "anomalyco/opencode" }
    $url = "https://api.github.com/repos/$Repo/releases/latest"
    try {
        $resp = Invoke-RestMethod -Uri $url -Headers @{ "User-Agent" = "PortableAgentToolkit" } -UseBasicParsing
        if ($resp.tag_name) { return $resp.tag_name }
        if ($resp.url) {
            $resp2 = Invoke-RestMethod -Uri $resp.url -Headers @{ "User-Agent" = "PortableAgentToolkit" } -UseBasicParsing
            if ($resp2.tag_name) { return $resp2.tag_name }
        }
    } catch {}

    # Fallback without API rate limits: follow redirect of https://github.com/$Repo/releases/latest
    try {
        $req = [System.Net.HttpWebRequest]::Create("https://github.com/$Repo/releases/latest")
        $req.AllowAutoRedirect = $false
        $req.UserAgent = "PortableAgentToolkit"
        $res = $req.GetResponse()
        $loc = $res.GetResponseHeader("Location")
        $res.Close()
        if ($loc -match "/releases/tag/(.+)$") {
            return $matches[1]
        }
    } catch {}

    throw "Could not resolve latest release for $Repo"
}

function Get-GithubAssetUrl {
    param([Parameter(Mandatory)][string]$Repo, [Parameter(Mandatory)][string]$Asset)
    if ($Repo -eq "sst/opencode") { $Repo = "anomalyco/opencode" }
    $tag = Get-LatestGithubRelease -Repo $Repo
    return "https://github.com/$Repo/releases/download/$tag/$Asset"
}

function Install-Gum {
    param([Parameter(Mandatory)][string]$Target)
    $gumExe = Join-Path $Target "bin\windows\gum-windows-amd64.exe"
    $gumAlt = Join-Path $Target "bin\windows\gum.exe"
    $gumBinAlt = Join-Path $Target "bin\gum-windows-amd64.exe"
    $gumBinAlt2 = Join-Path $Target "bin\gum.exe"
    if (Test-Path $gumExe) { return $gumExe }
    if (Test-Path $gumAlt) { return $gumAlt }
    if (Test-Path $gumBinAlt) { return $gumBinAlt }
    if (Test-Path $gumBinAlt2) { return $gumBinAlt2 }

    $version = "0.17.0"
    $url = "https://github.com/charmbracelet/gum/releases/download/v$version/gum_${version}_Windows_x86_64.zip"
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    $oldPref = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $url -OutFile (Join-Path $tmp "gum.zip") -UseBasicParsing -Headers @{ "User-Agent" = "PortableAgentToolkit" }
    } finally {
        $ProgressPreference = $oldPref
    }
    Expand-Archive -Path (Join-Path $tmp "gum.zip") -DestinationPath $tmp
    New-Item -ItemType Directory -Force -Path (Split-Path $gumExe) | Out-Null
    $extracted = Join-Path $tmp "gum_${version}_Windows_x86_64\gum.exe"
    if (Test-Path $extracted) {
        Copy-Item $extracted $gumExe -Force
        Copy-Item $extracted $gumAlt -Force
    } else {
        $anyGum = Get-ChildItem -Path $tmp -Filter "gum.exe" -Recurse | Select-Object -First 1
        if ($anyGum) {
            Copy-Item $anyGum.FullName $gumExe -Force
            Copy-Item $anyGum.FullName $gumAlt -Force
        }
    }
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    return $gumExe
}
