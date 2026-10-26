# Usage: .\dev-environment.ps1 <target_dir>
# Mirrors components/dev-environment.sh (execution-verified on Linux,
# including the zig-as-rust-linker fix). This copy is untested (no Windows
# hardware available during development).
param([Parameter(Mandatory)][string]$Target)
. "$PSScriptRoot\..\lib\common.ps1"

$JqExe = Join-Path $Target "bin\windows\jq-windows-amd64.exe"
if (-not (Test-Path $JqExe)) { Write-Host "Run core-agent-stack.ps1 first (jq missing)." -ForegroundColor Red; exit 1 }
New-Item -ItemType Directory -Force -Path (Join-Path $Target "dev") | Out-Null

function Install-Zig {
    Write-Host "== Zig (C/C++) =="
    $json = (Invoke-WebRequest -Uri "https://ziglang.org/download/index.json" -UseBasicParsing).Content | ConvertFrom-Json
    $versions = $json.PSObject.Properties.Name | Where-Object { $_ -ne "master" }
    $version = ($versions | Sort-Object { [version]($_ -replace '^(\d+\.\d+\.\d+).*','$1') } | Select-Object -Last 1)
    $entry = $json.$version."x86_64-windows"
    Write-Host "  version $version"
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    $fname = Split-Path -Leaf $entry.tarball
    Get-DownloadVerify -Url $entry.tarball -Dest (Join-Path $tmp $fname) -ExpectedSha256 $entry.shasum
    Expand-Archive -Path (Join-Path $tmp $fname) -DestinationPath $tmp
    $zigDir = Join-Path $Target "dev\zig"
    Remove-Item -Recurse -Force $zigDir -ErrorAction SilentlyContinue
    Get-ChildItem $tmp -Directory | Select-Object -First 1 | ForEach-Object { Move-Item $_.FullName $zigDir }
    Remove-Item -Recurse -Force $tmp
    Write-Host "  installed to dev\zig\"
}

function Install-Rust {
    Write-Host "== Rust (rustc + cargo, no rustup) =="
    $triple = "x86_64-pc-windows-msvc"
    $toml = (Invoke-WebRequest -Uri "https://static.rust-lang.org/dist/channel-rust-stable.toml" -UseBasicParsing).Content
    $version = [regex]::Match($toml, '(?s)\[pkg\.rust\].*?version = "([0-9.]+)').Groups[1].Value
    $urlMatch = [regex]::Match($toml, "(?s)\[pkg\.rust\.target\.$triple\].*?url = `"([^`"]+)`"")
    $shaMatch = [regex]::Match($toml, "(?s)\[pkg\.rust\.target\.$triple\].*?hash = `"([^`"]+)`"")
    Write-Host "  version $version"
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    $fname = Split-Path -Leaf $urlMatch.Groups[1].Value
    Get-DownloadVerify -Url $urlMatch.Groups[1].Value -Dest (Join-Path $tmp $fname) -ExpectedSha256 $shaMatch.Groups[1].Value
    # rust-lang's Windows tarball needs the same install.sh (MSVC builds still
    # ship a POSIX installer meant for msys2/git-bash) -- if that's not
    # available, extract manually: the tarball's rustc/cargo/*/bin already
    # contain usable .exe files directly, no install step strictly required.
    tar -xzf (Join-Path $tmp $fname) -C $tmp
    $rustDir = Join-Path $Target "dev\rust"
    Remove-Item -Recurse -Force $rustDir -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $rustDir | Out-Null
    Get-ChildItem $tmp -Directory | ForEach-Object {
        Get-ChildItem $_.FullName -Directory | ForEach-Object {
            $componentDir = Join-Path $_.FullName ""
            if ((Test-Path (Join-Path $_.FullName "bin")) -or (Test-Path (Join-Path $_.FullName "lib"))) {
                Copy-Item (Join-Path $_.FullName "*") $rustDir -Recurse -Force
            }
        }
    }
    Remove-Item -Recurse -Force $tmp

    # Same zig-as-linker fix as Linux/macOS: rustc alone doesn't link.
    $zigExe = Join-Path $Target "dev\zig\zig.exe"
    $wrapperPath = Join-Path $rustDir "zigcc-linker.cmd"
    Set-Content -Path $wrapperPath -Value "@echo off`r`n`"$zigExe`" cc %*"
    # CRITICAL: Forward slashes are required in TOML to avoid invalid escape sequence errors in Windows paths
    $wrapperPathForward = $wrapperPath -replace '\\', '/'
    Set-Content -Path (Join-Path $rustDir "config.toml") -Value @"
[target.$triple]
linker = "$wrapperPathForward"
"@
    Write-Host "  installed to dev\rust\ (linker: zig cc, no system cc/MSVC needed)"
}

function Install-Node {
    Write-Host "== Node.js + npm (React via 'npm create vite@latest') =="
    $index = (Invoke-WebRequest -Uri "https://nodejs.org/dist/index.json" -UseBasicParsing -Headers @{ "User-Agent" = "PortableAgentToolkit" }).Content | ConvertFrom-Json
    $lts = ($index | Where-Object { $_.lts -ne $false })[0]
    $version = $lts.version
    Write-Host "  version $version"
    $fname = "node-$version-win-x64.zip"
    $url = "https://nodejs.org/dist/$version/$fname"
    $shaContent = (Invoke-WebRequest -Uri "https://nodejs.org/dist/$version/SHASUMS256.txt" -UseBasicParsing -Headers @{ "User-Agent" = "PortableAgentToolkit" }).Content
    $sha = ($shaContent -split "\r?\n" | Where-Object { $_ -match [regex]::Escape($fname) }) -replace '\s.*',''
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Get-DownloadVerify -Url $url -Dest (Join-Path $tmp $fname) -ExpectedSha256 $sha
    Expand-Archive -Path (Join-Path $tmp $fname) -DestinationPath $tmp
    $nodeDir = Join-Path $Target "dev\node"
    Remove-Item -Recurse -Force $nodeDir -ErrorAction SilentlyContinue
    Get-ChildItem $tmp -Directory | Select-Object -First 1 | ForEach-Object { Move-Item $_.FullName $nodeDir }
    Remove-Item -Recurse -Force $tmp
    Write-Host "  installed to dev\node\"
}

function Install-Python {
    Write-Host "== Python (python-build-standalone) =="
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/astral-sh/python-build-standalone/releases/latest" -UseBasicParsing -Headers @{ "User-Agent" = "PortableAgentToolkit" }
    $asset = $release.assets | Where-Object { $_.name -match '^cpython-3\.13\.\d+\+\d+-x86_64-pc-windows-msvc-install_only\.tar\.gz$' } | Select-Object -First 1
    if (-not $asset) { Write-Host "Could not find a matching Python build" -ForegroundColor Red; return }
    Write-Host "  $($asset.name)"
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Get-DownloadVerify -Url $asset.browser_download_url -Dest (Join-Path $tmp $asset.name)
    tar -xzf (Join-Path $tmp $asset.name) -C $tmp
    $pyDir = Join-Path $Target "dev\python"
    Remove-Item -Recurse -Force $pyDir -ErrorAction SilentlyContinue
    Move-Item (Join-Path $tmp "python") $pyDir
    Remove-Item -Recurse -Force $tmp
    Write-Host "  installed to dev\python\"
}

Install-Zig
Install-Rust
Install-Node
Install-Python
Write-Host ""
Write-Host "Dev environment installed into $(Join-Path $Target 'dev')"
Write-Host "Run .\dev.bat from the install root to enter a shell with all four toolchains on PATH."
