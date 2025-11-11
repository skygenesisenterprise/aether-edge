#!/bin/bash

# Aether Edge Security Generator
# Generates cryptographically secure secrets and configuration values

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
MIN_LENGTH=32
MAX_LENGTH=64
SPECIAL_CHARS='!@#$%^&*()_+-='
NUMERIC_CHARS='0123456789'
ALPHABET='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

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

log_header() {
    echo -e "${PURPLE}=== $1 ===${NC}"
}

# Cryptographically secure random generator
generate_secure_random() {
    local length=${1:-32}
    local type=${2:-hex}
    
    case $type in
        "hex")
            openssl rand -hex $((length / 2))
            ;;
        "base64")
            openssl rand -base64 $length | tr -d '=+/' | cut -c1-$length
            ;;
        "alphanumeric")
            openssl rand -base64 $length | tr -dc 'A-Za-z0-9' | head -c $length
            ;;
        "password")
            # Generate strong password with mixed characters
            local password=""
            local char_sets=("$ALPHABET" "$NUMERIC_CHARS" "$SPECIAL_CHARS")
            
            # Ensure at least one character from each set
            password+=$(echo -n "$ALPHABET" | fold -w1 | shuf | head -n1)
            password+=$(echo -n "$NUMERIC_CHARS" | fold -w1 | shuf | head -n1)
            password+=$(echo -n "$SPECIAL_CHARS" | fold -w1 | shuf | head -n1)
            
            # Fill remaining length with random characters from all sets
            local all_chars="$ALPHABET$NUMERIC_CHARS$SPECIAL_CHARS"
            local remaining=$((length - 3))
            password+=$(echo -n "$all_chars" | fold -w1 | shuf | head -n$remaining)
            
            # Shuffle the password
            echo -n "$password" | fold -w1 | shuf | tr -d '\n'
            ;;
        "uuid")
            uuidgen | tr -d '-' | head -c $length
            ;;
        "numeric")
            openssl rand -base64 $length | tr -dc '0-9' | head -c $length
            ;;
        *)
            openssl rand -hex $((length / 2))
            ;;
    esac
}

# Generate JWT secret
generate_jwt_secret() {
    local length=${1:-64}
    log_info "Generating JWT secret ($length bytes)..." >&2
    generate_secure_random $length base64
}

# Generate database password
generate_db_password() {
    local length=${1:-32}
    log_info "Generating database password ($length characters)..." >&2
    generate_secure_random $length password
}

# Generate session secret
generate_session_secret() {
    local length=${1:-32}
    log_info "Generating session secret ($length bytes)..." >&2
    generate_secure_random $length hex
}

# Generate API key
generate_api_key() {
    local length=${1:-64}
    local prefix=${2:-"aether"}
    log_info "Generating API key ($length characters)..." >&2
    local key_part=$(generate_secure_random $((length - ${#prefix} - 1)) alnum)
    echo "${prefix}_${key_part}"
}

# Generate encryption key
generate_encryption_key() {
    local length=${1:-32}
    log_info "Generating encryption key ($length bytes)..." >&2
    generate_secure_random $length hex
}

# Generate webhook secret
generate_webhook_secret() {
    local length=${1:-32}
    log_info "Generating webhook secret ($length bytes)..." >&2
    generate_secure_random $length base64
}

# Generate database connection string
generate_db_connection_string() {
    local db_type=${1:-"postgresql"}
    local host=${2:-"localhost"}
    local port=${3:-"5432"}
    local database=${4:-"aether_edge"}
    local username=${5:-"aether_user"}
    local password=${6:-"default_password"}
    
    log_info "Generating database connection string..." >&2
    case "$db_type" in
        "postgresql"|"pg")
            echo "postgresql://$username:$password@$host:$port/$database"
            ;;
        "mysql")
            echo "mysql://$username:$password@$host:$port/$database"
            ;;
        "sqlite")
            echo "sqlite:./data/$database.db"
            ;;
        *)
            echo "unknown://$username:$password@$host:$port/$database"
            ;;
    esac
}

# Generate Redis connection string
generate_redis_connection_string() {
    local host=${1:-"localhost"}
    local port=${2:-"6379"}
    local password=${3:-""}
    
    log_info "Generating Redis connection string..." >&2
    if [[ -n "$password" ]]; then
        echo "redis://:$password@$host:$port"
    else
        echo "redis://$host:$port"
    fi
}

# Generate SSL certificate self-signed (for development)
generate_ssl_cert() {
    local domain=${1:-localhost}
    local country=${2:-US}
    local state=${3:-California}
    local locality=${4:-"San Francisco"}
    local organization=${5:-"Aether Edge"}
    
    log_info "Generating self-signed SSL certificate for $domain..."
    
    # Generate private key
    openssl genrsa -out "${domain}.key" 2048
    
    # Generate certificate signing request
    openssl req -new -key "${domain}.key" -out "${domain}.csr" -subj "/C=$country/ST=$state/L=$locality/O=$organization/CN=$domain"
    
    # Generate self-signed certificate
    openssl x509 -req -days 365 -in "${domain}.csr" -signkey "${domain}.key" -out "${domain}.crt"
    
    # Clean up CSR
    rm "${domain}.csr"
    
    log_success "SSL certificate generated: ${domain}.crt, ${domain}.key"
}

# Generate environment file
generate_env_file() {
    local env_file=${1:-".env.production"}
    local build_type=${2:-"enterprise"}
    local database_type=${3:-"postgresql"}
    local domain=${4:-"your-domain.com"}
    
    log_header "Generating Environment File"
    
    # Generate all secrets
    local server_secret=$(generate_jwt_secret 64)
    local db_password=$(generate_db_password 32)
    local session_secret=$(generate_session_secret 32)
    local encryption_key=$(generate_encryption_key 32)
    local webhook_secret=$(generate_webhook_secret 32)
    local api_key=$(generate_api_key 64)
    local db_connection=$(generate_db_connection_string $database_type "postgres" 5432 "aether_edge" "aether_user" "$db_password")
    local redis_password=$(generate_secure_random 16 alnum)
    local redis_connection=$(generate_redis_connection_string "redis" 6379 "$redis_password")
    
    # Create environment file
    cat > "$env_file" << EOF
# =============================================================================
# ETHER EDGE PRODUCTION CONFIGURATION
# Generated on: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# Build Type: $build_type
# Database: $database_type
# =============================================================================

# =============================================================================
# SECURITY SECRETS (GENERATED)
# =============================================================================
SERVER_SECRET=$server_secret
POSTGRES_PASSWORD=$db_password
SESSION_SECRET=$session_secret
ENCRYPTION_KEY=$encryption_key
WEBHOOK_SECRET=$webhook_secret
API_KEY=$api_key

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================
DATABASE_URL=$db_connection
REDIS_URL=$redis_connection
DB_POOL_MIN=2
DB_POOL_MAX=10
DB_CONNECTION_TIMEOUT=30000

# =============================================================================
# DOMAIN CONFIGURATION
# =============================================================================
DASHBOARD_URL=https://$domain
DOMAIN_NAME=$domain
ACME_EMAIL=admin@$domain

# =============================================================================
# BUILD CONFIGURATION
# =============================================================================
BUILD_TYPE=$build_type
DATABASE_TYPE=$database_type
NODE_ENV=production

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================
LOG_LEVEL=info
GERBIL_LOG_LEVEL=info
TRAEFIK_LOG_LEVEL=INFO

# =============================================================================
# FEATURE FLAGS
# =============================================================================
REQUIRE_EMAIL_VERIFICATION=true
DISABLE_SIGNUP_WITHOUT_INVITE=false
DISABLE_USER_CREATE_ORG=false
ALLOW_RAW_RESOURCES=false
ENABLE_INTEGRATION_API=true
ENABLE_CLIENTS=true

# =============================================================================
# PERFORMANCE CONFIGURATION
# =============================================================================
NODE_OPTIONS=--max-old-space-size=4096
CACHE_TTL=3600
CACHE_MAX_SIZE=1000

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=15m
SESSION_TIMEOUT=24h
MAX_FILE_SIZE=10MB
ENABLE_CSP=true
ENABLE_HSTS=true
ENABLE_XSS_PROTECTION=true

# =============================================================================
# BACKUP CONFIGURATION
# =============================================================================
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=30
EOF

    log_success "Environment file generated: $env_file"
    log_warning "Please review and customize the configuration before deployment"
}

# Validate generated secrets
validate_secrets() {
    local secret=$1
    local name=${2:-"secret"}
    
    if [[ ${#secret} -lt $MIN_LENGTH ]]; then
        log_error "$name is too short (minimum $MIN_LENGTH characters)"
        return 1
    fi
    
    if [[ ${#secret} -gt $MAX_LENGTH ]]; then
        log_warning "$name is longer than recommended maximum ($MAX_LENGTH characters)"
    fi
    
    # Check for common weak patterns
    if [[ "$secret" =~ (password|secret|key|admin|123|test) ]]; then
        log_warning "$name contains common patterns - consider regenerating"
    fi
    
    # Check entropy (basic check)
    local unique_chars=$(echo "$secret" | fold -w1 | sort -u | wc -l)
    local total_chars=${#secret}
    local entropy_ratio=$((unique_chars * 100 / total_chars))
    
    if [[ $entropy_ratio -lt 50 ]]; then
        log_warning "$name has low entropy ($entropy_ratio% unique characters)"
    else
        log_success "$name has good entropy ($entropy_ratio% unique characters)"
    fi
}

# Generate password policy compliant password
generate_compliant_password() {
    local min_length=${1:-16}
    local max_length=${2:-32}
    local length=$((MIN_LENGTH + RANDOM % (max_length - min_length + 1)))
    
    log_info "Generating password policy compliant password ($length characters)..."
    
    local password=""
    local char_sets=("$ALPHABET" "$NUMERIC_CHARS" "$SPECIAL_CHARS")
    
    # Ensure minimum requirements
    password+=$(echo -n "${char_sets[0]}" | fold -w1 | shuf | head -n1)  # lowercase
    password+=$(echo -n "${char_sets[0]}" | tr '[:lower:]' '[:upper:]' | fold -w1 | shuf | head -n1)  # uppercase
    password+=$(echo -n "${char_sets[1]}" | fold -w1 | shuf | head -n1)  # number
    password+=$(echo -n "${char_sets[2]}" | fold -w1 | shuf | head -n1)  # special
    
    # Fill remaining length
    local all_chars="${char_sets[0]}${char_sets[1]}${char_sets[2]}"
    local remaining=$((length - 4))
    password+=$(echo -n "$all_chars" | fold -w1 | shuf | head -n$remaining)
    
    # Shuffle and return
    echo -n "$password" | fold -w1 | shuf | tr -d '\n'
}

# Show help
show_help() {
    echo -e "${CYAN}Aether Edge Security Generator${NC}"
    echo
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  server-secret [length]     Generate server secret (default: 64 bytes)"
    echo "  db-password [length]       Generate database password (default: 32 chars)"
    echo "  session-secret [length]    Generate session secret (default: 32 bytes)"
    echo "  api-key [length] [prefix] Generate API key (default: 64 chars)"
    echo "  encryption-key [length]    Generate encryption key (default: 32 bytes)"
    echo "  webhook-secret [length]    Generate webhook secret (default: 32 bytes)"
    echo "  password [min] [max]      Generate policy-compliant password"
    echo "  db-connection [type]       Generate database connection string"
    echo "  redis-connection [host]    Generate Redis connection string"
    echo "  ssl-cert [domain]           Generate self-signed SSL certificate"
    echo "  env-file [build] [db]     Generate complete environment file"
    echo "  validate [secret]           Validate secret strength"
    echo "  all                        Generate all secrets"
    echo "  interactive                 Interactive mode"
    echo "  help                       Show this help"
    echo
    echo "Examples:"
    echo "  $0 server-secret 64"
    echo "  $0 db-password 32"
    echo "  $0 api-key 64 myapp"
    echo "  $0 env-file enterprise postgresql mydomain.com"
    echo "  $0 interactive"
}

# Interactive mode
interactive_mode() {
    log_header "Interactive Security Generator"
    
    echo -e "${CYAN}Select what to generate:${NC}"
    echo "1) Server Secret"
    echo "2) Database Password"
    echo "3) Session Secret"
    echo "4) API Key"
    echo "5) Encryption Key"
    echo "6) Webhook Secret"
    echo "7) Password (Policy Compliant)"
    echo "8) Database Connection String"
    echo "9) Redis Connection String"
    echo "10) SSL Certificate"
    echo "11) Complete Environment File"
    echo "12) All Secrets"
    
    read -p "Enter your choice (1-12): " choice
    
    case $choice in
        1)
            read -p "Enter length (default: 64): " length
            generate_jwt_secret ${length:-64}
            ;;
        2)
            read -p "Enter length (default: 32): " length
            generate_db_password ${length:-32}
            ;;
        3)
            read -p "Enter length (default: 32): " length
            generate_session_secret ${length:-32}
            ;;
        4)
            read -p "Enter length (default: 64): " length
            read -p "Enter prefix (default: aether): " prefix
            generate_api_key ${length:-64} ${prefix:-aether}
            ;;
        5)
            read -p "Enter length (default: 32): " length
            generate_encryption_key ${length:-32}
            ;;
        6)
            read -p "Enter length (default: 32): " length
            generate_webhook_secret ${length:-32}
            ;;
        7)
            read -p "Enter minimum length (default: 16): " min_len
            read -p "Enter maximum length (default: 32): " max_len
            generate_compliant_password ${min_len:-16} ${max_len:-32}
            ;;
        8)
            read -p "Database type (postgresql/mysql/sqlite): " db_type
            read -p "Host (default: localhost): " host
            read -p "Port (default: 5432): " port
            read -p "Database name (default: aether_edge): " database
            read -p "Username (default: aether_user): " username
            generate_db_connection_string "${db_type:-postgresql}" "${host:-localhost}" "${port:-5432}" "${database:-aether_edge}" "${username:-aether_user}"
            ;;
        9)
            read -p "Redis host (default: localhost): " host
            read -p "Redis port (default: 6379): " port
            read -p "Redis password (press enter for no auth): " password
            generate_redis_connection_string "${host:-localhost}" "${port:-6379}" "$password"
            ;;
        10)
            read -p "Domain name (default: localhost): " domain
            read -p "Country code (default: US): " country
            read -p "State (default: California): " state
            read -p "Locality (default: San Francisco): " locality
            read -p "Organization (default: Aether Edge): " organization
            generate_ssl_cert "${domain:-localhost}" "${country:-US}" "${state:-California}" "${localality:-San Francisco}" "${organization:-Aether Edge}"
            ;;
        11)
            read -p "Build type (oss/saas/enterprise, default: enterprise): " build_type
            read -p "Database type (sqlite/postgresql, default: postgresql): " database_type
            read -p "Domain name (default: your-domain.com): " domain
            generate_env_file ".env.production" "${build_type:-enterprise}" "${database_type:-postgresql}" "${domain:-your-domain.com}"
            ;;
        12)
            log_header "Generating All Secrets"
            echo
            echo -e "${GREEN}Server Secret:${NC} $(generate_jwt_secret 64)"
            echo -e "${GREEN}Database Password:${NC} $(generate_db_password 32)"
            echo -e "${GREEN}Session Secret:${NC} $(generate_session_secret 32)"
            echo -e "${GREEN}API Key:${NC} $(generate_api_key 64)"
            echo -e "${GREEN}Encryption Key:${NC} $(generate_encryption_key 32)"
            echo -e "${GREEN}Webhook Secret:${NC} $(generate_webhook_secret 32)"
            echo -e "${GREEN}Password:${NC} $(generate_compliant_password)"
            ;;
        *)
            log_error "Invalid choice"
            return 1
            ;;
    esac
}

# Generate all secrets
generate_all() {
    log_header "Generating All Security Secrets"
    echo
    
    echo -e "${CYAN}1. Server Secret (64 bytes):${NC}"
    local server_secret=$(generate_jwt_secret 64)
    echo "$server_secret"
    validate_secrets "$server_secret" "Server Secret"
    echo
    
    echo -e "${CYAN}2. Database Password (32 characters):${NC}"
    local db_password=$(generate_db_password 32)
    echo "$db_password"
    validate_secrets "$db_password" "Database Password"
    echo
    
    echo -e "${CYAN}3. Session Secret (32 bytes):${NC}"
    local session_secret=$(generate_session_secret 32)
    echo "$session_secret"
    validate_secrets "$session_secret" "Session Secret"
    echo
    
    echo -e "${CYAN}4. API Key (64 characters):${NC}"
    local api_key=$(generate_api_key 64)
    echo "$api_key"
    validate_secrets "$api_key" "API Key"
    echo
    
    echo -e "${CYAN}5. Encryption Key (32 bytes):${NC}"
    local encryption_key=$(generate_encryption_key 32)
    echo "$encryption_key"
    validate_secrets "$encryption_key" "Encryption Key"
    echo
    
    echo -e "${CYAN}6. Webhook Secret (32 bytes):${NC}"
    local webhook_secret=$(generate_webhook_secret 32)
    echo "$webhook_secret"
    validate_secrets "$webhook_secret" "Webhook Secret"
    echo
    
    echo -e "${CYAN}7. Policy-Compliant Password:${NC}"
    local password=$(generate_compliant_password)
    echo "$password"
    validate_secrets "$password" "Password"
    echo
    
    log_success "All secrets generated successfully!"
    log_warning "Store these secrets in a secure location"
}

# Main execution
main() {
    case "${1:-}" in
        "server-secret")
            generate_jwt_secret "${2:-64}"
            ;;
        "db-password")
            generate_db_password "${2:-32}"
            ;;
        "session-secret")
            generate_session_secret "${2:-32}"
            ;;
        "api-key")
            generate_api_key "${2:-64}" "${3:-aether}"
            ;;
        "encryption-key")
            generate_encryption_key "${2:-32}"
            ;;
        "webhook-secret")
            generate_webhook_secret "${2:-32}"
            ;;
        "password")
            generate_compliant_password "${2:-16}" "${3:-32}"
            ;;
        "db-connection")
            generate_db_connection_string "$2" "$3" "$4" "$5" "$6" "$7"
            ;;
        "redis-connection")
            generate_redis_connection_string "$2" "$3" "$4"
            ;;
        "ssl-cert")
            generate_ssl_cert "$2" "$3" "$4" "$5" "$6"
            ;;
        "env-file")
            generate_env_file "$2" "$3" "$4"
            ;;
        "validate")
            validate_secrets "$2" "${3:-secret}"
            ;;
        "all")
            generate_all
            ;;
        "interactive")
            interactive_mode
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Check dependencies
if ! command -v openssl &> /dev/null; then
    log_error "OpenSSL is required but not installed"
    exit 1
fi

if ! command -v uuidgen &> /dev/null; then
    log_warning "uuidgen not found, some features may not work"
fi

# Run main function
main "$@"