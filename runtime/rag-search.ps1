# Usage: .\rag-search.bat "<query>" [-List]
# Mirrors rag-search.sh (execution-verified on Linux, including a specificity-
# scoring fix). Untested on Windows.
param(
    [switch]$List,
    [string]$Query = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RagDir = Join-Path $ScriptDir "rag"
if (-not (Test-Path $RagDir)) {
    $parentRag = Join-Path (Split-Path -Parent $ScriptDir) "rag"
    if (Test-Path $parentRag) { $RagDir = $parentRag }
}
$Index = Join-Path $RagDir "index.json"
$TopicsDir = Join-Path $RagDir "topics"

if (-not (Test-Path $Index)) { Write-Host "RAG index not found at $Index"; exit 1 }
$data = Get-Content $Index -Raw | ConvertFrom-Json

if ($List) {
    foreach ($t in $data.topics) { Write-Host "$($t.id)  -  $($t.description)" }
    exit 0
}
if (-not $Query) { Write-Host 'Usage: .\rag-search.bat "<query>" [-List]'; exit 1 }
$queryLc = $Query.ToLower()

if ($queryLc -match '(0/1|0-1|01|zero.one|zero-one)\s*knapsack') {
    Write-Host "NOT COVERED: this corpus only has the FRACTIONAL knapsack (greedy) topic."
    Write-Host "0/1 knapsack (items indivisible) is a DIFFERENT problem that needs dynamic"
    Write-Host "programming -- greedy does not give the optimal answer for it."
    exit 0
}

$scores = @{}
$candidates = @()
foreach ($t in $data.topics) {
    $score = 0
    $idWords = $t.id -replace '_', ' '
    if ($queryLc.Contains($idWords)) { $score += $idWords.Length }
    foreach ($alias in $t.aliases) {
        $aliasLc = $alias.ToLower()
        if ($queryLc.Contains($aliasLc)) { $score += $aliasLc.Length }
    }
    $scores[$t.id] = $score
    if ($score -gt 0) { $candidates += "$($t.id) ($($t.description)) score=$score" }
}

foreach ($t in $data.topics) {
    if ($t.id -like "*_overview") {
        $others = $data.topics | Where-Object { $_.id -ne $t.id -and $_.category -eq $t.category -and $scores[$_.id] -gt 0 }
        if ($others) { $scores[$t.id] = 0 }
    }
}

$bestScore = 0; $bestId = ""; $bestFile = ""; $bestCount = 0
foreach ($t in $data.topics) {
    $score = $scores[$t.id]
    if ($score -gt $bestScore) { $bestScore = $score; $bestId = $t.id; $bestFile = $t.file; $bestCount = 1 }
    elseif ($score -eq $bestScore -and $score -gt 0) { $bestCount++ }
}

if ($bestScore -eq 0) {
    Write-Host "NO MATCH: nothing in this corpus matches `"$Query`"."
    Write-Host "Available topics (run: .\rag-search.bat -List):"
    foreach ($t in $data.topics) { Write-Host "  - $($t.id): $($t.description)" }
    exit 0
}
if ($bestCount -gt 1) {
    Write-Host "AMBIGUOUS: more than one topic matched `"$Query`" equally well:"
    foreach ($c in $candidates) { Write-Host "  $c" }
    exit 0
}
Get-Content (Join-Path $TopicsDir $bestFile) -Raw | Write-Output
