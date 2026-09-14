# Usage: .\dev.bat
# Drops you into a subshell with the portable C/C++ (zig), Rust, Node.js/npm,
# and Python toolchains on PATH. Mirrors dev.sh. Untested on Windows.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DevDir = Join-Path $ScriptDir "dev"

if (-not (Test-Path $DevDir)) {
    Write-Host "No dev\ directory found at $DevDir -- run install.ps1 with the dev environment component selected first."
    exit 1
}

$env:Path = "$DevDir\zig;$DevDir\rust\bin;$DevDir\node;$DevDir\python;$env:Path"
$env:CARGO_HOME = Join-Path $DevDir "rust"
$env:RUSTUP_HOME = Join-Path $DevDir "rust"
$env:npm_config_cache = Join-Path $DevDir "node\cache"
$env:PIP_CACHE_DIR = Join-Path $DevDir "python\cache"
New-Item -ItemType Directory -Force -Path $env:npm_config_cache, $env:PIP_CACHE_DIR | Out-Null

Write-Host "Portable dev environment active. Available:"
if (Test-Path "$DevDir\zig\zig.exe") { Write-Host "  zig     $(& "$DevDir\zig\zig.exe" version)  (zig cc / zig c++ for C and C++)" }
if (Test-Path "$DevDir\rust\bin\rustc.exe") { Write-Host "  rustc   $((& "$DevDir\rust\bin\rustc.exe" --version) -replace 'rustc ','')" }
if (Test-Path "$DevDir\node\node.exe") { Write-Host "  node    $(& "$DevDir\node\node.exe" --version)  (React: npm create vite@latest)" }
if (Test-Path "$DevDir\python\python.exe") { Write-Host "  python  $((& "$DevDir\python\python.exe" --version) -replace 'Python ','')" }
Write-Host ""
Write-Host "Type 'exit' to leave and return your shell to normal."
Write-Host ""

& powershell -NoExit
