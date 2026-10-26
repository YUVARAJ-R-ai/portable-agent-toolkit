# Usage: .\rag-search.bat "<query>" [-List]
param(
    [switch]$List,
    [switch]$l,
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$QueryParts
)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$RagDir = Join-Path $ScriptDir "rag"
if (-not (Test-Path $RagDir)) {
    $parentRag = Join-Path (Split-Path -Parent $ScriptDir) "rag"
    if (Test-Path $parentRag) { $RagDir = $parentRag }
}
$Index = Join-Path $RagDir "index.json"
$TopicsDir = Join-Path $RagDir "topics"

if (-not (Test-Path $Index)) { Write-Host "RAG index not found at $Index" -ForegroundColor Red; exit 1 }
$data = Get-Content $Index -Raw -Encoding UTF8 | ConvertFrom-Json

$Query = ""
if ($QueryParts) {
    $Query = ($QueryParts -join " ").Trim()
}

$isList = $List -or $l -or ($Query -eq "--list") -or ($Query -eq "-list") -or ($Query -eq "/list") -or ($Query -eq "-l")
if ($isList) {
    foreach ($t in $data.topics) { Write-Host "$($t.id)  -  $($t.description)" }
    exit 0
}
if (-not $Query) { Write-Host 'Usage: .\rag-search.bat "<query>" [-List]'; exit 1 }
$queryLc = $Query.ToLower()

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
Get-Content (Join-Path $TopicsDir $bestFile) -Raw -Encoding UTF8 | Write-Output
