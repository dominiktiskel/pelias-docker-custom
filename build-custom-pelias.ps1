# PowerShell script to build and push custom Pelias OpenStreetMap image (multi-platform)
# Usage: .\build-custom-pelias.ps1 [version] [-NoPush] [-NoTest] [-Amd64Only]
# Example: .\build-custom-pelias.ps1 v2.9.4

param(
    [string]$Version = "latest",
    [switch]$NoPush,
    [switch]$NoTest,
    [switch]$Amd64Only   # Build only linux/amd64 (skip arm64)
)

$ErrorActionPreference = "Stop"

$IMAGE        = "tiskel/openstreetmap"
$TAG          = "${IMAGE}:${Version}"
$BUILDER      = "pelias-multiarch"
$PLATFORMS    = if ($Amd64Only) { "linux/amd64" } else { "linux/amd64,linux/arm64" }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Building Custom Pelias OpenStreetMap" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Image:     $TAG" -ForegroundColor Yellow
Write-Host "  Platforms: $PLATFORMS" -ForegroundColor Yellow
Write-Host ""

# Check if Docker is running
try {
    docker ps | Out-Null
} catch {
    Write-Host "ERROR: Docker is not running!" -ForegroundColor Red
    exit 1
}

# Navigate to pelias root (parent of docker/)
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$PeliasRoot = Split-Path -Parent $ScriptDir
Set-Location $PeliasRoot
Write-Host "Working directory: $(Get-Location)" -ForegroundColor Gray
Write-Host ""

# ── Ensure multi-platform builder ─────────────────────────────────────────────
# The default 'docker' driver does not support multi-platform push;
# we need a builder with the 'docker-container' driver.
if (-not $Amd64Only) {
    $builderExists = docker buildx inspect $BUILDER 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[buildx] Creating multi-platform builder: $BUILDER" -ForegroundColor Gray
        docker buildx create --name $BUILDER --driver docker-container `
            --driver-opt image=moby/buildkit:latest --bootstrap
    } else {
        Write-Host "[buildx] Using existing builder: $BUILDER" -ForegroundColor Gray
    }
    docker buildx use $BUILDER
}

# ── Step 1: Build ─────────────────────────────────────────────────────────────
Write-Host "Step 1: Building Docker image..." -ForegroundColor Green

$BuildArgs = @(
    "buildx", "build",
    "--platform", $PLATFORMS,
    "-f", "openstreetmap/Dockerfile.custom",
    "-t", $TAG
)

if (-not $NoPush) {
    # Multi-platform images must be pushed directly (cannot be loaded locally)
    $BuildArgs += "--push"
    Write-Host "        (will push directly during build)" -ForegroundColor Gray
} else {
    if ($Amd64Only) {
        $BuildArgs += "--load"
    } else {
        $BuildArgs += @("--output", "type=image,push=false")
        Write-Host "        WARNING: Multi-platform --NoPush produces a cache-only build." -ForegroundColor Yellow
        Write-Host "        Use -Amd64Only to also --load into local daemon." -ForegroundColor Yellow
    }
}

$BuildArgs += "."
& docker @BuildArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green
Write-Host ""

# ── Step 2: Tests (only when image is available locally) ──────────────────────
if (-not $NoTest) {
    if ((-not $NoPush) -or $Amd64Only) {
        Write-Host "Step 2: Running tests..." -ForegroundColor Green
        docker run --rm --platform linux/amd64 $TAG npm test

        if ($LASTEXITCODE -ne 0) {
            Write-Host "WARNING: Tests failed! Continuing anyway..." -ForegroundColor Yellow
        } else {
            Write-Host "Tests passed!" -ForegroundColor Green
        }
        Write-Host ""
    } else {
        Write-Host "Step 2: Skipping tests (image not loaded locally in multi-platform --NoPush mode)." -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " SUCCESS!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Image:     $TAG" -ForegroundColor Yellow
Write-Host "  Platforms: $PLATFORMS" -ForegroundColor Yellow
Write-Host ""
Write-Host "To use this image, update docker-compose.yml:" -ForegroundColor Cyan
Write-Host "  openstreetmap:" -ForegroundColor White
Write-Host "    image: $TAG" -ForegroundColor Yellow
Write-Host ""
Write-Host "Then run:" -ForegroundColor Cyan
Write-Host "  pelias compose pull openstreetmap" -ForegroundColor White
Write-Host "  pelias import osm" -ForegroundColor White
Write-Host ""
