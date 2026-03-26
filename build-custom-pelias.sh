#!/usr/bin/env bash
# Build and push custom Pelias OpenStreetMap image (multi-platform: amd64 + arm64)
# Usage: ./build-custom-pelias.sh [version] [options]
# Example: ./build-custom-pelias.sh v2.9.4
#
# Options:
#   --no-push     Build only, do not push to Docker Hub
#   --no-test     Skip running tests
#   --amd64-only  Build only for linux/amd64

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
VERSION="latest"
NO_PUSH=false
NO_TEST=false
AMD64_ONLY=false
IMAGE="tiskel/openstreetmap"
BUILDER_NAME="pelias-multiarch"

# ── Argument parsing ──────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --no-push)    NO_PUSH=true ;;
    --no-test)    NO_TEST=true ;;
    --amd64-only) AMD64_ONLY=true ;;
    -*)           echo "Unknown option: $arg"; exit 1 ;;
    *)            VERSION="$arg" ;;
  esac
done

TAG="${IMAGE}:${VERSION}"

if [ "$AMD64_ONLY" = true ]; then
  PLATFORMS="linux/amd64"
else
  PLATFORMS="linux/amd64,linux/arm64"
fi

# ── Header ────────────────────────────────────────────────────────────────────
echo "========================================"
echo " Building Custom Pelias OpenStreetMap"
echo "========================================"
echo ""
echo "  Image:     $TAG"
echo "  Platforms: $PLATFORMS"
echo ""

# ── Sanity checks ─────────────────────────────────────────────────────────────
if ! docker ps >/dev/null 2>&1; then
  echo "ERROR: Docker is not running!" >&2
  exit 1
fi

# Navigate to pelias root (parent of docker/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PELIAS_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PELIAS_ROOT"
echo "Working directory: $(pwd)"
echo ""

# ── Ensure multi-platform builder ─────────────────────────────────────────────
# The default 'docker' driver does not support multi-platform export/push;
# we need a builder with the 'docker-container' driver.
setup_builder() {
  if docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
    echo "[buildx] Using existing builder: $BUILDER_NAME"
  else
    echo "[buildx] Creating multi-platform builder: $BUILDER_NAME"
    docker buildx create \
      --name "$BUILDER_NAME" \
      --driver docker-container \
      --driver-opt image=moby/buildkit:latest \
      --bootstrap
  fi
  docker buildx use "$BUILDER_NAME"
}

if [ "$AMD64_ONLY" = false ]; then
  setup_builder
fi

# ── Step 1: Build ─────────────────────────────────────────────────────────────
echo "Step 1: Building Docker image..."

BUILD_ARGS=(
  buildx build
  --platform "$PLATFORMS"
  -f openstreetmap/Dockerfile.custom
  -t "$TAG"
)

if [ "$NO_PUSH" = false ]; then
  # With multi-platform + docker-container driver we must push directly;
  # loading multi-arch images into the local daemon is not supported.
  BUILD_ARGS+=(--push)
  echo "        (will push directly during build)"
else
  if [ "$AMD64_ONLY" = true ]; then
    # Single platform can be loaded into local daemon
    BUILD_ARGS+=(--load)
  else
    # Multi-platform cannot be loaded; build cache only
    BUILD_ARGS+=(--output type=image,push=false)
    echo "        WARNING: Multi-platform --no-push produces a cache-only build."
    echo "        Use --amd64-only to also --load into local daemon."
  fi
fi

BUILD_ARGS+=(.)

docker "${BUILD_ARGS[@]}"

echo "Build successful!"
echo ""

# ── Step 2: Tests (only when image is available locally) ──────────────────────
if [ "$NO_TEST" = false ]; then
  if [ "$NO_PUSH" = false ] || [ "$AMD64_ONLY" = true ]; then
    echo "Step 2: Running tests..."
    if docker run --rm --platform linux/amd64 "$TAG" npm test; then
      echo "Tests passed!"
    else
      echo "WARNING: Tests failed! Continuing anyway..."
    fi
    echo ""
  else
    echo "Step 2: Skipping tests (image not loaded locally in multi-platform --no-push mode)."
    echo ""
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo "========================================"
echo " SUCCESS!"
echo "========================================"
echo ""
echo "  Image: $TAG"
echo "  Platforms: $PLATFORMS"
echo ""
echo "To use this image, update docker-compose.yml:"
echo "  openstreetmap:"
echo "    image: $TAG"
echo ""
echo "Then run:"
echo "  pelias compose pull openstreetmap"
echo "  pelias import osm"
echo ""
