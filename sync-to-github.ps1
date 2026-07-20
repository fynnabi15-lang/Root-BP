# sync-to-github.ps1 — copy latest RootMenu.exe and push to origin
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $RepoRoot

$candidates = @(
    (Join-Path $RepoRoot "RootMenu.exe"),
    (Join-Path $RepoRoot "src\x64\Release\RootMenu.exe"),
    (Join-Path $RepoRoot "x64\Release\RootMenu.exe"),
    (Join-Path $RepoRoot "src\RootMenu\x64\Release\RootMenu.exe")
)

$src = $null
foreach ($c in $candidates) {
    if (Test-Path $c) {
        if (-not $src) { $src = Get-Item $c }
        else {
            $item = Get-Item $c
            if ($item.LastWriteTime -gt $src.LastWriteTime) { $src = $item }
        }
    }
}

if (-not $src) {
    Write-Error "RootMenu.exe not found. Build first (OutDir should be repo root)."
    exit 1
}

$dest = Join-Path $RepoRoot "RootMenu.exe"
if ($src.FullName -ne $dest) {
    Copy-Item $src.FullName $dest -Force
    Write-Host "Copied from $($src.FullName)"
} else {
    Write-Host "Using existing $dest"
}

git add RootMenu.exe
$status = git status --porcelain -- RootMenu.exe
if (-not $status) {
    Write-Host "No changes to RootMenu.exe — nothing to commit."
    exit 0
}

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git commit --trailer "Co-authored-by: Cursor <cursoragent@cursor.com>" -m "sync: update RootMenu.exe ($ts)"
$branch = git rev-parse --abbrev-ref HEAD
git push -u origin $branch
Write-Host "Pushed RootMenu.exe to origin/$branch"
Write-Host "URL: https://github.com/fynnabi15-lang/Root-BP/raw/$branch/RootMenu.exe"
