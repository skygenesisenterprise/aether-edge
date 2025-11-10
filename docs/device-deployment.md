# Aether Edge Device Deployment

This directory contains everything needed to deploy Aether Edge on hardware devices and embedded systems.

## 🚀 Quick Start

### Option 1: Using Makefile (Recommended)

```bash
# Build device image
make build-device

# Deploy on current hardware
make deploy-device

# Check device status
make status-device
```

### Option 2: Using Scripts

```bash
# Build device image
./scripts/build-device.sh

# Deploy on hardware
sudo ./scripts/device-deploy.sh

# Create deployment package
./scripts/build-device.sh latest docker.io/aetheredge --package
```

### Option 3: Using Docker Compose

```bash
# Set device build
npm run set:device

# Start with device compose
docker-compose -f docker-compose.device.yml up -d
```

## 📦 Files Overview

### Docker Configuration
- **`Dockerfile.device`** - Optimized Docker image for hardware devices
- **`docker-compose.device.yml`** - Docker Compose configuration for device deployment

### Scripts
- **`scripts/build-device.sh`** - Build device Docker images with multi-platform support
- **`scripts/device-deploy.sh`** - Deploy device on hardware with automatic configuration

### Configuration
- **`config/device.example.yml`** - Complete device configuration template
- **`Makefile.device`** - Simplified commands for device operations

## 🎯 Target Hardware

### Minimum Requirements
- **CPU**: ARMv7 / x86_64 500MHz
- **RAM**: 256MB minimum, 512MB recommended
- **Storage**: 512MB flash storage
- **Network**: Ethernet or WiFi connectivity

### Recommended Hardware
- **Raspberry Pi 4B** - 4GB RAM recommended
- **Intel NUC** - For x86_64 deployments
- **Custom ARM Boards** - Any ARMv7+ board with Debian support
- **Industrial PCs** - For rugged deployments

## 🔧 Configuration

### Basic Setup

1. **Copy configuration template:**
   ```bash
   cp config/device.example.yml config/device.yml
   ```

2. **Edit device settings:**
   ```yaml
   app:
     mode: device
     device_id: "my-device-001"
   
   device:
     model: "Raspberry Pi 4B"
     manufacturer: "Raspberry Pi Foundation"
   ```

3. **Deploy device:**
   ```bash
   make deploy-device
   ```

### Advanced Configuration

#### Hardware Acceleration
```yaml
hardware:
  crypto_acceleration:
    enabled: true
    driver: "openssl"  # or "hardware-specific"
```

#### LED Indicators
```yaml
hardware:
  led_indicators:
    power: "/sys/class/leds/power/brightness"
    status: "/sys/class/leds/status/brightness"
    network: "/sys/class/leds/network/brightness"
```

#### Watchdog
```yaml
hardware:
  watchdog:
    enabled: true
    timeout: 30s
    action: "reboot"
```

## 📊 Monitoring

### Health Checks

```bash
# Check device health
make health-device

# View device logs
make logs-device

# Check device status
make status-device
```

### Metrics

Device exposes Prometheus metrics on port 9090:

```bash
curl http://device-ip:9090/metrics
```

## 🔄 Updates

### Automatic Updates

```yaml
updates:
  auto_update: true
  check_interval: 24h
  backup_before_update: true
```

### Manual Updates

```bash
# Update running device
make update-device

# Build and deploy new version
make build-device
make deploy-device
```

## 🛠️ Development

### Local Development

```bash
# Start device in development mode
make dev-device

# Test device configuration
make test-device
```

### Building Packages

```bash
# Create deployment package
make package-device

# Multi-architecture build
make build-device-multi
```

## 🔒 Security

### Device Security

1. **Change default secret:**
   ```yaml
   server:
     secret: "your-secure-secret-here"
   ```

2. **Enable firewall:**
   ```bash
   ufw allow 3000/tcp  # API
   ufw allow 3002/tcp  # Dashboard
   ufw allow 51820/udp # WireGuard
   ```

3. **Secure SSH access:**
   ```yaml
   device_management:
     remote_access:
       enabled: true
       key_based_auth: true
   ```

## 📱 Access

### Web Interface

- **Dashboard**: http://device-ip:3002
- **API**: http://device-ip:3000
- **Metrics**: http://device-ip:9090/metrics

### Setup Token

The initial setup token is displayed in container logs:

```bash
docker logs aether-edge-device | grep "SETUP TOKEN"
```

## 🆘 Troubleshooting

### Common Issues

#### Device Won't Start
```bash
# Check logs
docker logs aether-edge-device

# Check configuration
docker exec aether-edge-device cat /opt/aether-edge/config/config.yml

# Restart device
docker restart aether-edge-device
```

#### Network Issues
```bash
# Check network connectivity
docker exec aether-edge-device ping -c 3 8.8.8.8

# Check WireGuard status
docker exec aether-edge-device wg show

# Check firewall rules
iptables -L -n
```

#### Performance Issues
```bash
# Check resource usage
docker stats aether-edge-device

# Check disk space
df -h /opt/aether-edge

# Check memory usage
free -h
```

### Recovery

#### Backup Device Data
```bash
make backup-device
```

#### Restore Device Data
```bash
make restore-device
```

#### Factory Reset
```bash
# Stop device
docker stop aether-edge-device

# Remove data
rm -rf /opt/aether-edge/data/*

# Restart device
docker start aether-edge-device
```

## 📚 Documentation

- **Main Documentation**: [docs.aether-edge.com](https://docs.aether-edge.com)
- **Device Guide**: [docs.aether-edge.com/device](https://docs.aether-edge.com/device)
- **API Reference**: [docs.aether-edge.com/api](https://docs.aether-edge.com/api)
- **Community**: [community.aether-edge.com](https://community.aether-edge.com)

## 🤝 Support

- **Issues**: [github.com/aether-edge/issues](https://github.com/aether-edge/issues)
- **Discussions**: [github.com/aether-edge/discussions](https://github.com/aether-edge/discussions)
- **Email**: device-support@aether-edge.com

## 📄 License

This device version of Aether Edge is licensed under the Apache License 2.0. See [LICENSE](../LICENSE) for details.