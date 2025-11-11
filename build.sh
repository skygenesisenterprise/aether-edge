#!/bin/bash

# Aether Edge Build Script
# Automates building different variants of Aether Edge

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
BUILD_TYPE="oss"
DATABASE_TYPE="sqlite"
IMAGE_NAME="aether-edge"
IMAGE_TAG="latest"
PUSH_TO_REGISTRY=false
REGISTRY_URL=""
DOCKERFILE="Dockerfile"
BUILD_CONTEXT="."

# Help function
show_help() {
    echo -e "${BLUE}Aether Edge Build Script${NC}"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -t, --type TYPE        Build type: oss, saas, enterprise (default: oss)"
    echo "  -d, --database DB      Database: sqlite, pg (default: sqlite)"
    echo "  -i, --image NAME       Image name (default: aether-edge)"
    echo "  -g, --tag TAG         Image tag (default: latest)"
    echo "  -r, --registry URL      Registry URL for pushing"
    echo "  -p, --push            Push to registry after build"
    echo "  -f, --file FILE       Dockerfile path (default: Dockerfile)"
    echo "  -c, --context PATH     Build context (default: .)"
    echo "  -h, --help            Show this help"
    echo
    echo "Examples:"
    echo "  # Build OSS version with SQLite"
    echo "  $0 --type oss --database sqlite"
    echo
    echo "  # Build Enterprise version with PostgreSQL"
    echo "  $0 --type enterprise --database pg --tag v1.0.0"
    echo
    echo "  # Build and push to registry"
    echo "  $0 --type saas --registry my-registry.com --push"
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type)
                BUILD_TYPE="$2"
                shift 2
                ;;
            -d|--database)
                DATABASE_TYPE="$2"
                shift 2
                ;;
            -i|--image)
                IMAGE_NAME="$2"
                shift 2
                ;;
            -g|--tag)
                IMAGE_TAG="$2"
                shift 2
                ;;
            -r|--registry)
                REGISTRY_URL="$2"
                shift 2
                ;;
            -p|--push)
                PUSH_TO_REGISTRY=true
                shift
                ;;
            -f|--file)
                DOCKERFILE="$2"
                shift 2
                ;;
            -c|--context)
                BUILD_CONTEXT="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Validate arguments
validate_args() {
    # Validate build type
    if [[ ! "$BUILD_TYPE" =~ ^(oss|saas|enterprise)$ ]]; then
        log_error "Invalid build type: $BUILD_TYPE. Must be: oss, saas, or enterprise"
        exit 1
    fi
    
    # Validate database type
    if [[ ! "$DATABASE_TYPE" =~ ^(sqlite|pg)$ ]]; then
        log_error "Invalid database type: $DATABASE_TYPE. Must be: sqlite or pg"
        exit 1
    fi
    
    # Check if Dockerfile exists
    if [[ ! -f "$DOCKERFILE" ]]; then
        log_error "Dockerfile not found: $DOCKERFILE"
        exit 1
    fi
    
    # Check if build context exists
    if [[ ! -d "$BUILD_CONTEXT" ]]; then
        log_error "Build context not found: $BUILD_CONTEXT"
        exit 1
    fi
}

# Show build configuration
show_config() {
    echo -e "${BLUE}=== Build Configuration ===${NC}"
    echo "Build Type: $BUILD_TYPE"
    echo "Database: $DATABASE_TYPE"
    echo "Image: $IMAGE_NAME:$IMAGE_TAG"
    echo "Dockerfile: $DOCKERFILE"
    echo "Context: $BUILD_CONTEXT"
    if [[ -n "$REGISTRY_URL" ]]; then
        echo "Registry: $REGISTRY_URL"
    fi
    echo "Push to Registry: $PUSH_TO_REGISTRY"
    echo
}

# Prepare build environment
prepare_build() {
    log_info "Preparing build environment..."
    
    # Set environment variables for Docker build
    export DOCKER_BUILDKIT=1
    
    # Prepare build arguments
    BUILD_ARGS=(
        "--build-arg" "BUILD=$BUILD_TYPE"
        "--build-arg" "DATABASE=$DATABASE_TYPE"
    )
    
    # Prepare image tag
    if [[ -n "$REGISTRY_URL" ]]; then
        FULL_IMAGE_TAG="$REGISTRY_URL/$IMAGE_NAME:$IMAGE_TAG"
    else
        FULL_IMAGE_TAG="$IMAGE_NAME:$IMAGE_TAG"
    fi
    
    log_success "Build environment prepared"
}

# Build Docker image
build_image() {
    log_info "Building Docker image..."
    log_info "This may take several minutes..."
    
    # Build command
    docker build \
        "${BUILD_ARGS[@]}" \
        -f "$DOCKERFILE" \
        -t "$FULL_IMAGE_TAG" \
        "$BUILD_CONTEXT"
    
    if [[ $? -eq 0 ]]; then
        log_success "Docker image built successfully"
        log_info "Image: $FULL_IMAGE_TAG"
    else
        log_error "Docker build failed"
        exit 1
    fi
}

# Push to registry
push_to_registry() {
    if [[ "$PUSH_TO_REGISTRY" == true ]]; then
        log_info "Pushing image to registry..."
        
        docker push "$FULL_IMAGE_TAG"
        
        if [[ $? -eq 0 ]]; then
            log_success "Image pushed to registry successfully"
        else
            log_error "Failed to push image to registry"
            exit 1
        fi
    fi
}

# Show image information
show_image_info() {
    log_info "Image information:"
    docker images "$FULL_IMAGE_TAG" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
}

# Generate build metadata
generate_metadata() {
    log_info "Generating build metadata..."
    
    METADATA_FILE="build-metadata.json"
    
    cat > "$METADATA_FILE" << EOF
{
    "build_type": "$BUILD_TYPE",
    "database": "$DATABASE_TYPE",
    "image": "$FULL_IMAGE_TAG",
    "build_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
    "git_branch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')",
    "docker_version": "$(docker --version)"
}
EOF
    
    log_success "Build metadata saved to $METADATA_FILE"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary files..."
    # Add any cleanup operations here
}

# Main build function
main() {
    echo -e "${BLUE}=== Aether Edge Build Script ===${NC}"
    echo
    
    parse_args "$@"
    validate_args
    show_config
    prepare_build
    build_image
    push_to_registry
    show_image_info
    generate_metadata
    
    log_success "Build process completed successfully!"
}

# Set up trap for cleanup
trap cleanup EXIT

# Run main function
main "$@"