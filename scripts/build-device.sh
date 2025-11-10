#!/bin/bash
# =============================================================================
# Aether Edge Device Build Script
# Build optimized Docker images for hardware deployment
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="aetheredge/device"
VERSION=${1:-latest}
REGISTRY=${2:-"docker.io/aetheredge"}
PLATFORMS="linux/amd64,linux/arm64"

echo -e "${BLUE}🔧 Aether Edge Device Build Script${NC}"
echo -e "${BLUE}=====================================${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

# Check if buildx is available for multi-platform builds
if ! docker buildx version &> /dev/null; then
    print_warning "Docker buildx not found, falling back to single platform build"
    PLATFORMS="linux/$(uname -m | sed 's/x86_64/amd64/')"
    USE_BUILDX=false
else
    print_status "Using Docker buildx for multi-platform builds"
    USE_BUILDX=true
fi

# Create buildx builder if needed
if [ "$USE_BUILDX" = true ]; then
    if ! docker buildx ls | grep -q "aether-builder"; then
        print_status "Creating buildx builder..."
        docker buildx create --name aether-builder --use --bootstrap
    else
        docker buildx use aether-builder
    fi
fi

# Build arguments
BUILD_ARGS=""
if [ -n "$HTTP_PROXY" ]; then
    BUILD_ARGS="$BUILD_ARGS --build-arg HTTP_PROXY=$HTTP_PROXY"
fi
if [ -n "$HTTPS_PROXY" ]; then
    BUILD_ARGS="$BUILD_ARGS --build-arg HTTPS_PROXY=$HTTPS_PROXY"
fi

print_status "Building Aether Edge Device image..."
print_status "Image: $REGISTRY/$IMAGE_NAME:$VERSION"
print_status "Platforms: $PLATFORMS"

# Build the image
if [ "$USE_BUILDX" = true ]; then
    docker buildx build \
        --platform "$PLATFORMS" \
        --tag "$REGISTRY/$IMAGE_NAME:$VERSION" \
        --tag "$REGISTRY/$IMAGE_NAME:latest" \
        --push \
        $BUILD_ARGS \
        -f Dockerfile.device \
        .
else
    docker build \
        --tag "$REGISTRY/$IMAGE_NAME:$VERSION" \
        --tag "$REGISTRY/$IMAGE_NAME:latest" \
        $BUILD_ARGS \
        -f Dockerfile.device \
        .
fi

if [ $? -eq 0 ]; then
    print_status "✅ Build completed successfully!"
    echo
    echo -e "${GREEN}Available images:${NC}"
    echo "  $REGISTRY/$IMAGE_NAME:$VERSION"
    echo "  $REGISTRY/$IMAGE_NAME:latest"
    echo
    echo -e "${BLUE}To run the device:${NC}"
    echo "  docker run -d --name aether-edge-device --privileged --network host $REGISTRY/$IMAGE_NAME:$VERSION"
    echo
    echo -e "${BLUE}To use docker-compose:${NC}"
    echo "  docker-compose -f docker-compose.device.yml up -d"
else
    print_error "❌ Build failed!"
    exit 1
fi

# Optional: Generate device deployment package
if [ "$3" = "--package" ]; then
    print_status "Creating device deployment package..."
    
    PACKAGE_NAME="aether-edge-device-$VERSION"
    PACKAGE_DIR="./dist/$PACKAGE_NAME"
    
    mkdir -p "$PACKAGE_DIR"
    
    # Export image
    docker save "$REGISTRY/$IMAGE_NAME:$VERSION" | gzip > "$PACKAGE_DIR/aether-edge-device.tar.gz"
    
    # Copy deployment scripts
    cp scripts/device-deploy.sh "$PACKAGE_DIR/" 2>/dev/null || echo "#!/bin/bash" > "$PACKAGE_DIR/device-deploy.sh"
    cp docker-compose.device.yml "$PACKAGE_DIR/"
    cp config/device.example.yml "$PACKAGE_DIR/"
    
    # Create README
    cat > "$PACKAGE_DIR/README.md" << EOF
# Aether Edge Device Deployment Package

## Quick Start

1. Load the Docker image:
   \`\`\`bash
   docker load < aether-edge-device.tar.gz
   \`\`\`

2. Run with docker-compose:
   \`\`\`bash
   docker-compose -f docker-compose.device.yml up -d
   \`\`\`

3. Access the dashboard:
   - URL: http://device-ip:3002
   - Default setup token will be shown in logs

## Configuration

Edit \`config/device.example.yml\` before starting for custom settings.

## Support

- Documentation: https://docs.aether-edge.com/device
- Issues: https://github.com/aether-edge/issues
EOF
    
    # Create package archive
    cd ./dist
    tar -czf "$PACKAGE_NAME.tar.gz" "$PACKAGE_NAME/"
    cd ..
    
    print_status "✅ Deployment package created: ./dist/$PACKAGE_NAME.tar.gz"
fi

print_status "🎉 Device build process completed!"