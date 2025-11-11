#!/bin/bash

# Aether Edge Production Deployment Script
# This script automates the deployment of Aether Edge in production

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.production.yml"
ENV_FILE=".env.production"
BACKUP_DIR="./backups"
LOG_DIR="./logs"

# Functions
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check if files exist
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_error "Docker Compose file not found: $COMPOSE_FILE"
        exit 1
    fi
    
    if [[ ! -f "$ENV_FILE" ]]; then
        log_error "Environment file not found: $ENV_FILE"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Setup directories
setup_directories() {
    log_info "Setting up directories..."
    
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$LOG_DIR"/{app,gerbil,traefik}
    mkdir -p ./config/traefik/dynamic
    mkdir -p ./letsencrypt
    mkdir -p ./uploads
    mkdir -p ./monitoring
    
    log_success "Directories created"
}

# Generate secrets
generate_secrets() {
    log_info "Generating secure secrets..."
    
    # Check if secrets already exist
    if grep -q "your-very-secure-secret-key" "$ENV_FILE"; then
        log_warning "Default secrets detected. Generating new ones..."
        
        # Generate server secret
        SERVER_SECRET=$(openssl rand -hex 32)
        sed -i "s/your-very-secure-secret-key.*/SERVER_SECRET=$SERVER_SECRET/" "$ENV_FILE"
        
        # Generate database password
        DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        sed -i "s/your-secure-database-password.*/POSTGRES_PASSWORD=$DB_PASSWORD/" "$ENV_FILE"
        
        # Generate session secret
        SESSION_SECRET=$(openssl rand -hex 32)
        sed -i "s/your-session-secret-key.*/SESSION_SECRET=$SESSION_SECRET/" "$ENV_FILE"
        
        log_success "New secrets generated"
    else
        log_info "Secrets already configured"
    fi
}

# Validate configuration
validate_config() {
    log_info "Validating configuration..."
    
    # Source environment file
    source "$ENV_FILE"
    
    # Check required variables
    required_vars=("SERVER_SECRET" "POSTGRES_PASSWORD" "DASHBOARD_URL" "DOMAIN_NAME")
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            log_error "Required environment variable $var is not set"
            exit 1
        fi
    done
    
    # Validate domain format
    if [[ ! "$DOMAIN_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        log_error "Invalid domain name: $DOMAIN_NAME"
        exit 1
    fi
    
    log_success "Configuration validation passed"
}

# Build images
build_images() {
    log_info "Building Docker images..."
    
    # Build with production arguments
    docker build \
        -f Dockerfile.production \
        --build-arg BUILD="${BUILD_TYPE:-enterprise}" \
        --build-arg DATABASE="${DATABASE_TYPE:-pg}" \
        -t aether-edge:production \
        .
    
    log_success "Docker images built"
}

# Deploy services
deploy_services() {
    log_info "Deploying services..."
    
    # Use production environment file
    export COMPOSE_FILE="$COMPOSE_FILE"
    export ENV_FILE="$ENV_FILE"
    
    # Start services
    docker-compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d
    
    log_success "Services deployed"
}

# Wait for services to be healthy
wait_for_health() {
    log_info "Waiting for services to be healthy..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Health check attempt $attempt/$max_attempts..."
        
        # Check main application
        if docker-compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps | grep -q "healthy"; then
            log_success "All services are healthy"
            return 0
        fi
        
        sleep 10
        ((attempt++))
    done
    
    log_error "Services did not become healthy within expected time"
    return 1
}

# Setup backup cron job
setup_backup() {
    log_info "Setting up backup cron job..."
    
    # Create backup script
    cat > backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"

# Create database backup
docker exec aether-postgres pg_dump -U aether_user aether_edge > "$BACKUP_DIR/db_backup_$DATE.sql"

# Create configuration backup
tar -czf "$BACKUP_DIR/config_backup_$DATE.tar.gz" config/

# Clean old backups (keep last 7 days)
find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
EOF
    
    chmod +x backup.sh
    
    # Add to crontab if not exists
    if ! crontab -l | grep -q "backup.sh"; then
        (crontab -l 2>/dev/null; echo "0 2 * * * $(pwd)/backup.sh") | crontab -
        log_success "Backup cron job added"
    else
        log_info "Backup cron job already exists"
    fi
}

# Display deployment info
display_info() {
    log_success "Deployment completed successfully!"
    echo
    echo -e "${BLUE}=== Deployment Information ===${NC}"
    echo -e "Dashboard URL: ${GREEN}$DASHBOARD_URL${NC}"
    echo -e "Domain: ${GREEN}$DOMAIN_NAME${NC}"
    echo
    echo -e "${BLUE}=== Service Status ===${NC}"
    docker-compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps
    echo
    echo -e "${BLUE}=== Useful Commands ===${NC}"
    echo "View logs: docker-compose --env-file $ENV_FILE -f $COMPOSE_FILE logs -f"
    echo "Stop services: docker-compose --env-file $ENV_FILE -f $COMPOSE_FILE down"
    echo "Restart services: docker-compose --env-file $ENV_FILE -f $COMPOSE_FILE restart"
    echo
    echo -e "${BLUE}=== Next Steps ===${NC}"
    echo "1. Configure your domain DNS to point to this server"
    echo "2. Set up SSL certificates (Let's Encrypt will auto-generate)"
    echo "3. Create admin account via dashboard"
    echo "4. Configure monitoring (optional)"
}

# Main deployment function
main() {
    echo -e "${BLUE}=== Aether Edge Production Deployment ===${NC}"
    echo
    
    check_prerequisites
    setup_directories
    generate_secrets
    validate_config
    build_images
    deploy_services
    
    if wait_for_health; then
        setup_backup
        display_info
    else
        log_error "Deployment failed - services not healthy"
        docker-compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" logs
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    "build")
        build_images
        ;;
    "deploy")
        deploy_services
        ;;
    "logs")
        docker-compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" logs -f
        ;;
    "stop")
        docker-compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" down
        ;;
    "restart")
        docker-compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" restart
        ;;
    "status")
        docker-compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps
        ;;
    "backup")
        ./backup.sh
        ;;
    *)
        main
        ;;
esac