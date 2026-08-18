# Usage: .\core-agent-stack.ps1 <target_dir>
# Downloads koboldcpp, OpenCode, Goose, gum, and jq (Windows builds) into
# <target_dir>\bin\windows\. See core-agent-stack.sh for the execution-
# verified Linux version this mirrors; this copy is untested (no Windows
# hardware available during development).
param([Parameter(Mandatory)][string]$Target)

. "$PSScriptRoot\..\lib\common.ps1"
$BinDir = Join-Path $Target "bin\windows"
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

Write-Host "== koboldcpp =="
$koboldUrl = Get-GithubAssetUrl -Repo "LostRuins/koboldcpp" -Asset "koboldcpp-nocuda.exe"
Get-DownloadVerify -Url $koboldUrl -Dest (Join-Path $BinDir "koboldcpp-nocuda.exe")

Write-Host "== OpenCode =="
$ocUrl = Get-GithubAssetUrl -Repo "sst/opencode" -Asset "opencode-windows-x64.zip"
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp | Out-Null
Get-DownloadVerify -Url $ocUrl -Dest (Join-Path $tmp "opencode.zip")
Expand-Archive -Path (Join-Path $tmp "opencode.zip") -DestinationPath $tmp
Get-ChildItem -Path $tmp -Recurse -Filter "opencode.exe" | Select-Object -First 1 | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $BinDir "opencode.exe")
}
Remove-Item -Recurse -Force $tmp

Write-Host "== Goose =="
$gooseUrl = Get-GithubAssetUrl -Repo "block/goose" -Asset "goose-x86_64-pc-windows-msvc.zip"
$tmp2 = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp2 | Out-Null
Get-DownloadVerify -Url $gooseUrl -Dest (Join-Path $tmp2 "goose.zip")
Expand-Archive -Path (Join-Path $tmp2 "goose.zip") -DestinationPath $tmp2
Get-ChildItem -Path $tmp2 -Recurse -Filter "goose.exe" | Select-Object -First 1 | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $BinDir "goose.exe")
}
Remove-Item -Recurse -Force $tmp2

Write-Host "== gum =="
$gumExe = Install-Gum -Target $Target
if ($gumExe -ne (Join-Path $BinDir "gum-windows-amd64.exe")) {
    Copy-Item $gumExe (Join-Path $BinDir "gum-windows-amd64.exe") -Force
}

Write-Host "== jq (checksum-verified) =="
$jqUrl = Get-GithubAssetUrl -Repo "jqlang/jq" -Asset "jq-windows-amd64.exe"
$shaUrl = Get-GithubAssetUrl -Repo "jqlang/jq" -Asset "sha256sum.txt"
$shaContent = (Invoke-WebRequest -Uri $shaUrl -UseBasicParsing).Content
$jqSha = ($shaContent -split "`n" | Where-Object { $_ -match "jq-windows-amd64\.exe$" }) -replace '\s.*',''
Get-DownloadVerify -Url $jqUrl -Dest (Join-Path $BinDir "jq-windows-amd64.exe") -ExpectedSha256 $jqSha

Write-Host "Core agent stack installed into $BinDir"
foreach ($b in @("koboldcpp-nocuda.exe","opencode.exe","goose.exe","gum-windows-amd64.exe","jq-windows-amd64.exe")) {
    $p = Join-Path $BinDir $b
    if (Test-Path $p) { Write-Host "  $b`: present" } else { Write-Host "  $b`: MISSING" -ForegroundColor Red }
}
