#!/bin/bash
# =============================================================================
# Aether Edge Device Deployment Script
# Deploy Aether Edge on hardware devices
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEVICE_NAME=${1:-"aether-edge-device"}
IMAGE_NAME=${2:-"aetheredge/device:latest"}
DATA_DIR=${3:-"/opt/aether-edge"}
CONFIG_FILE=${4:-"$DATA_DIR/config/config.yml"}

echo -e "${BLUE}🚀 Aether Edge Device Deployment${NC}"
echo -e "${BLUE}===================================${NC}"

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

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root for device deployment"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    usermod -aG docker $USER
else
    print_status "Docker is already installed"
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    print_status "Docker Compose is already installed"
fi

# Create necessary directories
print_status "Creating directories..."
mkdir -p "$DATA_DIR"/{data,logs,config}

# Pull the latest device image
print_status "Pulling Aether Edge Device image..."
docker pull "$IMAGE_NAME"

# Check if device is already running
if docker ps -q -f name="$DEVICE_NAME" | grep -q .; then
    print_warning "Device is already running. Stopping it first..."
    docker stop "$DEVICE_NAME" || true
    docker rm "$DEVICE_NAME" || true
fi

# Generate device configuration if not exists
if [ ! -f "$CONFIG_FILE" ]; then
    print_status "Generating device configuration..."
    
    # Generate device ID
    DEVICE_ID=$(cat /proc/sys/kernel/random/uuid | tr -d '\n')
    
    # Get system information
    MODEL=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Unknown")
    MANUFACTURER=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "Unknown")
    
    cat > "$CONFIG_FILE" << EOF
# Aether Edge Device Configuration
# Generated on $(date)

app:
  mode: device
  dashboard_url: http://$(hostname -I | awk '{print $1}'):3002
  log_level: info
  device_id: "$DEVICE_ID"

device:
  model: "$MODEL"
  manufacturer: "$MANUFACTURER"
  firmware_version: "1.0.0"
  capabilities:
    - hardware-acceleration
    - offline-mode
    - embedded-database
    - wireguard-support

network:
  auto_discovery: true
  fallback_connectivity: true
  wireguard:
    enabled: true
    port: 51820

database:
  type: sqlite
  path: $DATA_DIR/data/aether-edge.db
  max_size: 100MB

storage:
  data_path: $DATA_DIR/data
  log_path: $DATA_DIR/logs
  config_path: $DATA_DIR/config
  max_log_size: 50MB
  log_retention_days: 7

server:
  secret: "$(openssl rand -hex 32)"

flags:
  require_email_verification: false
  disable_signup_without_invite: true
  disable_user_create_org: true
  allow_raw_resources: true
  enable_integration_api: true
  enable_clients: true
  enable_device_mode: true
EOF
    
    print_status "Configuration generated: $CONFIG_FILE"
    print_status "Device ID: $DEVICE_ID"
fi

# Deploy the device
print_status "Deploying Aether Edge Device..."

docker run -d \
    --name "$DEVICE_NAME" \
    --privileged \
    --network host \
    --restart unless-stopped \
    -v "$DATA_DIR/data:/opt/aether-edge/data" \
    -v "$DATA_DIR/logs:/opt/aether-edge/logs" \
    -v "$DATA_DIR/config:/opt/aether-edge/config" \
    -v /sys:/sys:ro \
    -v /proc:/proc:ro \
    -v /dev:/dev \
    -e NODE_ENV=production \
    -e ENVIRONMENT=device \
    "$IMAGE_NAME"

# Wait for container to start
print_status "Waiting for device to start..."
sleep 10

# Check if container is running
if docker ps -q -f name="$DEVICE_NAME" | grep -q .; then
    print_status "✅ Device deployed successfully!"
    echo
    echo -e "${GREEN}Device Information:${NC}"
    echo "  Name: $DEVICE_NAME"
    echo "  Image: $IMAGE_NAME"
    echo "  Data Directory: $DATA_DIR"
    echo "  Config File: $CONFIG_FILE"
    echo
    echo -e "${GREEN}Access URLs:${NC}"
    echo "  Dashboard: http://$(hostname -I | awk '{print $1}'):3002"
    echo "  API: http://$(hostname -I | awk '{print $1}'):3000"
    echo
    echo -e "${GREEN}Management Commands:${NC}"
    echo "  View logs: docker logs -f $DEVICE_NAME"
    echo "  Stop device: docker stop $DEVICE_NAME"
    echo "  Restart device: docker restart $DEVICE_NAME"
    echo "  Update device: docker pull $IMAGE_NAME && docker stop $DEVICE_NAME && $0"
    echo
    echo -e "${GREEN}Setup Token:${NC}"
    docker logs "$DEVICE_NAME" 2>&1 | grep -A 5 "SETUP TOKEN GENERATED" || echo "Check logs for setup token"
else
    print_error "❌ Failed to start device"
    print_error "Check logs with: docker logs $DEVICE_NAME"
    exit 1
fi

# Create systemd service for auto-start
if [ "$5" = "--systemd" ]; then
    print_status "Creating systemd service..."
    
    cat > "/etc/systemd/system/aether-edge-device.service" << EOF
[Unit]
Description=Aether Edge Device
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$DATA_DIR
ExecStart=/usr/bin/docker run -d \\
    --name $DEVICE_NAME \\
    --privileged \\
    --network host \\
    --restart unless-stopped \\
    -v $DATA_DIR/data:/opt/aether-edge/data \\
    -v $DATA_DIR/logs:/opt/aether-edge/logs \\
    -v $DATA_DIR/config:/opt/aether-edge/config \\
    -v /sys:/sys:ro \\
    -v /proc:/proc:ro \\
    -v /dev:/dev \\
    -e NODE_ENV=production \\
    -e ENVIRONMENT=device \\
    $IMAGE_NAME
ExecStop=/usr/bin/docker stop $DEVICE_NAME
ExecStopPost=/usr/bin/docker rm $DEVICE_NAME
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable aether-edge-device.service
    print_status "✅ Systemd service created and enabled"
fi

print_status "🎉 Device deployment completed!"