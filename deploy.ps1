param(
    [string]$ZipFile    = "",
    [string]$SourcePath = "C:\Users\cvillareale\Downloads\thenapolitan"
)

$RepoPath  = "C:\Users\cvillareale\thenapolitan-site"
$TempUnzip = "$env:TEMP\thenapolitan-deploy"

$Files = @(
    "index.html",
    "services.html",
    "portfolio.html",
    "resources.html",
    "credentials.html",
    "faq.html",
    "styles.css",
    "favicon.svg"
)

# STEP 1: Resolve source
if ($ZipFile -ne "" -and (Test-Path $ZipFile)) {
    Write-Host "`nUnzipping $ZipFile ..." -ForegroundColor Cyan
    if (Test-Path $TempUnzip) { Remove-Item $TempUnzip -Recurse -Force }
    New-Item -ItemType Directory -Path $TempUnzip | Out-Null
    Expand-Archive -Path $ZipFile -DestinationPath $TempUnzip -Force
    $contents = Get-ChildItem $TempUnzip
    if ($contents.Count -eq 1 -and $contents[0].PSIsContainer) {
        $SourcePath = $contents[0].FullName
        Write-Host "  Found subfolder: $($contents[0].Name)" -ForegroundColor DarkGray
    } else {
        $SourcePath = $TempUnzip
    }
    Write-Host "  Unzipped to $SourcePath" -ForegroundColor Green
} elseif ($ZipFile -ne "") {
    Write-Host "  Zip file not found: $ZipFile" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nUsing source folder: $SourcePath" -ForegroundColor Cyan
}

# STEP 2: Verify repo
if (-not (Test-Path $RepoPath)) {
    Write-Host "`n  Repo not found at $RepoPath" -ForegroundColor Red
    exit 1
}

# STEP 3: Copy files
Write-Host "`nCopying files..." -ForegroundColor Cyan
$copied  = 0
$skipped = 0

foreach ($file in $Files) {
    $src = Join-Path $SourcePath $file
    $dst = Join-Path $RepoPath $file
    if (Test-Path $src) {
        Copy-Item $src $dst -Force
        Write-Host "  OK $file" -ForegroundColor Green
        $copied++
    } else {
        Write-Host "  SKIP $file (not found)" -ForegroundColor Yellow
        $skipped++
    }
}

Write-Host "`n  $copied copied, $skipped skipped." -ForegroundColor DarkGray

if ($copied -eq 0) {
    Write-Host "`n  Nothing to deploy." -ForegroundColor Red
    exit 1
}

# STEP 4: Git push
Write-Host "`nPushing to GitHub..." -ForegroundColor Cyan
Set-Location $RepoPath
git add .
$status = git status --porcelain
if (-not $status) {
    Write-Host "`n  No changes detected." -ForegroundColor Yellow
    exit 0
}
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
git commit -m "Site update - $timestamp"
git push origin main

# STEP 5: Cleanup
if (Test-Path $TempUnzip) { Remove-Item $TempUnzip -Recurse -Force }

Write-Host "`n  Done! Vercel redeploys in ~30 seconds." -ForegroundColor Green
Write-Host "  https://www.thenapolitan.com`n" -ForegroundColor White
