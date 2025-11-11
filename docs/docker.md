# Docker Documentation for Aether Edge

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Docker Compose Files](#docker-compose-files)
4. [Development Setup](#development-setup)
5. [Production Deployment](#production-deployment)
6. [Device Deployment](#device-deployment)
7. [Environment Variables](#environment-variables)
8. [Volumes and Persistence](#volumes-and-persistence)
9. [Networking](#networking)
10. [Health Checks](#health-checks)
11. [Build Arguments](#build-arguments)
12. [Troubleshooting](#troubleshooting)
13. [Best Practices](#best-practices)

## Overview

Aether Edge uses Docker for containerization across different deployment scenarios:
- **Development**: Hot-reload environment with database services
- **Production**: Multi-service deployment with load balancing
- **Device**: Edge device deployment with hardware access

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Node.js 22+ (for local development)
- At least 4GB RAM
- 10GB available disk space

## Docker Compose Files

### Main Compose Files

| File | Purpose | Environment |
|------|---------|-------------|
| `docker-compose.yml` | Development environment | Development |
| `docker-compose.example.yml` | Production template | Production |
| `docker-compose.device.yml` | Edge device deployment | Device/Production |
| `docker-compose.pgr.yml` | PostgreSQL migrations | Database |
| `docker-compose.drizzle.yml` | Drizzle ORM tools | Development |

### Development Compose Files

| File | Purpose |
|------|---------|
| `.devcontainer/docker-compose.yml` | VS Code Dev Container |
| `install/config/docker-compose.yml` | Installation scripts |
| `install/config/crowdsec/docker-compose.yml` | Security services |

## Development Setup

### Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd aether-edge

# Start development environment
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop environment
docker-compose down
```

### Development Services

The development compose file includes:

- **app**: Main application with hot reload
- **postgres**: PostgreSQL database (port 5433)
- **redis**: Redis cache (port 6380)

### Port Mappings

| Service | Host Port | Container Port | Purpose |
|---------|-----------|----------------|---------|
| app | 3000-3003 | 3000-3003 | Application APIs |
| postgres | 5433 | 5432 | Database |
| redis | 6380 | 6379 | Cache |

### Volume Mounts

Development volumes enable hot reload:

```yaml
volumes:
  - ./src:/app/src              # Source code
  - ./server:/app/server        # Server code
  - ./public:/app/public        # Static assets
  - ./messages:/app/messages    # i18n files
  - ./config:/app/config        # Configuration
```

## Production Deployment

### Production Setup

1. **Copy the example compose file:**
   ```bash
   cp docker-compose.example.yml docker-compose.prod.yml
   ```

2. **Configure environment:**
   ```bash
   mkdir -p config
   # Copy your configuration files to config/
   ```

3. **Start production services:**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

### Production Services

- **pangolin**: Main application
- **gerbil**: WireGuard gateway service
- **traefik**: Reverse proxy and load balancer

### Production Networking

Production uses a custom bridge network with IPv6 support:

```yaml
networks:
  default:
    driver: bridge
    name: pangolin
    enable_ipv6: true
```

### Health Checks

Production services include comprehensive health checks:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3001/api/v1/"]
  interval: "3s"
  timeout: "3s"
  retries: 15
```

## Device Deployment

### Device Setup

Device deployment is optimized for edge hardware:

```bash
# Build and deploy device image
docker-compose -f docker-compose.device.yml up -d
```

### Device Features

- **Privileged mode**: Required for WireGuard and hardware access
- **Host networking**: Direct network interface access
- **Hardware access**: Mount system directories for hardware interaction
- **Persistent storage**: Bind mounts for data, logs, and config

### Device Services

| Service | Purpose | Optional |
|---------|---------|----------|
| aether-edge-device | Main device service | No |
| device-monitor | System monitoring | Yes (monitoring profile) |
| device-logs | Log aggregation | Yes (logging profile) |

### Device Volumes

```yaml
volumes:
  device_data:    # /opt/aether-edge/data
  device_logs:    # /opt/aether-edge/logs  
  device_config:  # /opt/aether-edge/config
```

## Environment Variables

### Development Variables

```yaml
environment:
  - NODE_ENV=development
  - ENVIRONMENT=dev
  - POSTGRES_CONNECTION_STRING=postgresql://postgres:password@postgres:5432/postgres
```

### Production Variables

Configure these in your environment or `.env` file:

```bash
NODE_ENV=production
ENVIRONMENT=production
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://host:6379
SECRET_KEY=your-secret-key
```

### Device Variables

```yaml
environment:
  - NODE_ENV=production
  - ENVIRONMENT=device
  - TZ=UTC
```

## Volumes and Persistence

### Development Volumes

- **postgres_data**: PostgreSQL data directory
- Named volumes for database persistence

### Production Volumes

- **./config**: Configuration files
- **./config/letsencrypt**: SSL certificates
- **./config/traefik**: Traefik configuration

### Device Volumes

Bind mounts for direct filesystem access:

```yaml
volumes:
  - device_data:/opt/aether-edge/data
  - device_logs:/opt/aether-edge/logs
  - device_config:/opt/aether-edge/config
  - /sys:/sys:ro
  - /proc:/proc:ro
  - /dev:/dev
```

## Networking

### Development Network

Default bridge network with service discovery.

### Production Network

Custom bridge network with IPv6 support:

```yaml
networks:
  default:
    driver: bridge
    name: pangolin
    enable_ipv6: true
```

### Device Network

Host networking for direct hardware access:

```yaml
network_mode: host
```

### Port Exposures

| Environment | Ports | Purpose |
|-------------|-------|---------|
| Development | 3000-3003, 5433, 6380 | App, DB, Redis |
| Production | 80, 443, 51820, 21820 | HTTP, HTTPS, WireGuard |
| Device | Host ports | Direct access |

## Health Checks

### Application Health Check

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3001/api/v1/"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### Device Health Check

```yaml
healthcheck:
  test: ["CMD", "/opt/aether-edge/scripts/device-health.sh"]
  interval: 60s
  timeout: 30s
  retries: 3
  start_period: 120s
```

## Build Arguments

### Multi-stage Build

The Dockerfile uses multi-stage builds for optimization:

#### Builder Stage

```dockerfile
FROM node:22-alpine AS builder
ARG BUILD=oss
ARG DATABASE=sqlite
```

Available build arguments:
- **BUILD**: `oss`, `saas`, `enterprise`
- **DATABASE**: `sqlite`, `pg`

#### Runner Stage

```dockerfile
FROM node:22-alpine AS runner
```

### Build Commands

```bash
# Build OSS version with SQLite
docker build --build-arg BUILD=oss --build-arg DATABASE=sqlite .

# Build Enterprise version with PostgreSQL
docker build --build-arg BUILD=enterprise --build-arg DATABASE=pg .

# Build development image
docker build -f Dockerfile.dev .
```

## Troubleshooting

### Common Issues

#### Port Conflicts

```bash
# Check port usage
netstat -tulpn | grep :3000

# Change ports in docker-compose.yml
ports:
  - "3001:3000"  # Use different host port
```

#### Permission Issues

```bash
# Fix volume permissions
sudo chown -R $USER:$USER ./config

# For device deployment
sudo chmod +x ./scripts/device-health.sh
```

#### Database Connection Issues

```bash
# Check database logs
docker-compose logs postgres

# Test connection
docker-compose exec app npm run db:test
```

#### Build Failures

```bash
# Clean build cache
docker builder prune -a

# Rebuild without cache
docker-compose build --no-cache
```

### Debug Commands

```bash
# View service logs
docker-compose logs -f [service-name]

# Execute commands in container
docker-compose exec app sh

# Inspect container
docker inspect [container-name]

# Check resource usage
docker stats
```

## Best Practices

### Development

1. **Use volume mounts** for hot reload
2. **Separate database** from application
3. **Use environment files** for configuration
4. **Regularly clean up** unused containers and images

### Production

1. **Use specific image tags** instead of `latest`
2. **Implement health checks** for all services
3. **Use restart policies** for high availability
4. **Secure sensitive data** with secrets management
5. **Monitor resource usage** and set limits

### Device Deployment

1. **Use bind mounts** for persistent data
2. **Implement proper logging** and log rotation
3. **Secure hardware access** with proper permissions
4. **Monitor system health** with appropriate tools
5. **Update images regularly** for security patches

### Security Considerations

1. **Run containers as non-root** users when possible
2. **Use read-only filesystems** for static content
3. **Implement network segmentation** between services
4. **Regular security scanning** of images
5. **Keep dependencies updated** to patch vulnerabilities

### Performance Optimization

1. **Use multi-stage builds** to reduce image size
2. **Implement proper caching** in Dockerfile
3. **Set appropriate resource limits**
4. **Use health checks** for load balancing
5. **Optimize layer ordering** in Dockerfile

## Advanced Usage

### Custom Networks

```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true
```

### Resource Limits

```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 1G
    reservations:
      cpus: '0.5'
      memory: 512M
```

### Logging Configuration

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### Secrets Management

```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt
```

## Migration and Updates

### Updating Services

```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d

# Run database migrations
docker-compose exec app npm run db:migrate
```

### Backup and Restore

```bash
# Backup volumes
docker run --rm -v pangolin_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres-backup.tar.gz -C /data .

# Restore volumes
docker run --rm -v pangolin_postgres_data:/data -v $(pwd):/backup alpine tar xzf /backup/postgres-backup.tar.gz -C /data
```

This documentation provides comprehensive guidance for using Docker with Aether Edge across all deployment scenarios. For specific use cases or additional help, refer to the project's README or contact the development team.