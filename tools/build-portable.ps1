# build-portable.ps1
# Build the portable (green / no-install) edition of SVG Viewer.
#
# Output:  dist-portable/SVG-Viewer-<version>-portable-x64.zip
# Contents of the ZIP:
#   svg-viewer.exe          (release-built single binary)
#   PORTABLE.txt            (marker enabling portable mode at runtime)
#   README.txt              (bilingual usage notes)
#   test-svgs/              (sample fixtures for first-run testing)

param(
    [switch]$SkipBuild,
    [string]$Version = '0.1.0'
)

$ErrorActionPreference = 'Stop'
Set-Location -Path (Split-Path -Parent $PSScriptRoot)
$root = Get-Location

if (-not $SkipBuild) {
    Write-Host '== Building release ==' -ForegroundColor Cyan
    & npm run tauri build
    if ($LASTEXITCODE -ne 0) { throw "tauri build failed (exit $LASTEXITCODE)" }
}

$exe = Join-Path $root 'src-tauri/target/release/svg-viewer.exe'
if (-not (Test-Path $exe)) { throw "Release exe not found: $exe" }

$outDir = Join-Path $root 'dist-portable'
$stageName = "SVG-Viewer-$Version-portable-x64"
$stage = Join-Path $outDir $stageName
$zipPath = Join-Path $outDir "$stageName.zip"

Write-Host "== Staging $stage ==" -ForegroundColor Cyan
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Path $stage | Out-Null

# Copy artifacts
Copy-Item $exe (Join-Path $stage 'svg-viewer.exe')
Copy-Item (Join-Path $root 'portable/PORTABLE.txt') $stage
Copy-Item (Join-Path $root 'portable/README.txt')   $stage
Copy-Item (Join-Path $root 'test-svgs') $stage -Recurse

# Optional: prune transient screenshot PNGs that may have accumulated in test-svgs
Get-ChildItem -Path (Join-Path $stage 'test-svgs') -Include '_*.png','_*.svg' -File -Recurse |
    Remove-Item -Force -ErrorAction SilentlyContinue

# Zip
Write-Host "== Zipping -> $zipPath ==" -ForegroundColor Cyan
if (Test-Path $zipPath) { Remove-Item -Force $zipPath }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zipPath -CompressionLevel Optimal

$size = (Get-Item $zipPath).Length
$sizeMb = [math]::Round($size / 1MB, 2)
Write-Host ''
Write-Host "OK  $zipPath  ($sizeMb MB)" -ForegroundColor Green
