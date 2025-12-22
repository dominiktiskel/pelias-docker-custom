# PowerShell script to build and push custom Pelias OpenStreetMap image
# Usage: .\build-custom-pelias.ps1 [version]
# Example: .\build-custom-pelias.ps1 v1.6.1

param(
    [string]$Version = "v1.6.1",
    [switch]$NoPush,
    [switch]$NoTest
)

$ErrorActionPreference = "Stop"

$IMAGE = "tiskel/openstreetmap"
$TAG = "${IMAGE}:${Version}"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Custom Pelias OpenStreetMap" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Image: $TAG" -ForegroundColor Yellow
Write-Host ""

# Check if Docker is running
try {
    docker ps | Out-Null
} catch {
    Write-Host "ERROR: Docker is not running!" -ForegroundColor Red
    exit 1
}

# Get script directory and navigate to pelias root (parent of docker/)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PeliasRoot = Split-Path -Parent $ScriptDir
Set-Location $PeliasRoot

Write-Host "Working directory: $(Get-Location)" -ForegroundColor Gray
Write-Host ""

Write-Host "Step 1: Building Docker image..." -ForegroundColor Green
docker build -f openstreetmap/Dockerfile.custom -t $TAG .

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green
Write-Host ""

# Run tests
if (-not $NoTest) {
    Write-Host "Step 2: Running tests..." -ForegroundColor Green
    docker run --rm $TAG npm test
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARNING: Tests failed!" -ForegroundColor Yellow
        Write-Host "Continuing with push anyway..." -ForegroundColor Yellow
    } else {
        Write-Host "Tests passed!" -ForegroundColor Green
    }
    Write-Host ""
}

# Push to Docker Hub
if (-not $NoPush) {
    Write-Host "Step 3: Pushing to Docker Hub..." -ForegroundColor Green
    Write-Host "Pushing: $TAG" -ForegroundColor Yellow
    
    docker push $TAG
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Docker push failed!" -ForegroundColor Red
        Write-Host "Make sure you are logged in: docker login" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Pushed successfully!" -ForegroundColor Green
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUCCESS!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Image: $TAG" -ForegroundColor Yellow
Write-Host ""
Write-Host "To use this image, update your docker-compose.yml:" -ForegroundColor Cyan
Write-Host "  openstreetmap:" -ForegroundColor White
Write-Host "    image: $TAG" -ForegroundColor Yellow
Write-Host ""
Write-Host "Then run:" -ForegroundColor Cyan
Write-Host "  cd projects/poland" -ForegroundColor White
Write-Host "  pelias compose pull openstreetmap" -ForegroundColor White
Write-Host "  pelias import osm" -ForegroundColor White
Write-Host ""

