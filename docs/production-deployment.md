# Production Deployment Guide for Aether Edge

## Overview

This guide provides step-by-step instructions for deploying Aether Edge in production using Docker Compose.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Domain name (for SSL certificates)
- Server with at least 4GB RAM and 20GB storage
- Ports 80, 443, 51820/UDP, 21820/UDP open

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/skygenesisenterprise/aether-edge.git 
cd aether-edge
```

### 2. Configure Environment
```bash
# Copy example configuration
cp docker-compose.example.yml docker-compose.yml
cp config/config.example.yml config/config.yml
```

### 3. Edit Configuration
Edit `config/config.yml` with your settings:
```yaml
app:
  dashboard_url: https://your-domain.com
  log_level: info

domains:
  domain1:
    base_domain: your-domain.com

server:
  secret: your-very-secure-secret-key-here

gerbil:
  base_endpoint: your-domain.com

orgs:
  block_size: 24
  subnet_group: 100.90.137.0/20

flags:
  require_email_verification: true
  disable_signup_without_invite: false
  disable_user_create_org: false
  allow_raw_resources: false
  enable_integration_api: true
  enable_clients: true
```

### 4. Start Services
```bash
docker-compose up -d
```

## Docker Configuration

### Docker File Information

**Dockerfile Path**: `./Dockerfile`
**Docker Context Path**: `.` (project root)
**Docker Build Stage**: `runner` (production stage)

### Build Arguments

The Dockerfile supports these build arguments:

- `BUILD`: Build type (`oss`, `saas`, `enterprise`)
  - Default: `oss`
  - Example: `--build-arg BUILD=enterprise`

- `DATABASE`: Database type (`sqlite`, `pg`)
  - Default: `sqlite`
  - Example: `--build-arg DATABASE=pg`

### Multi-stage Build

The Dockerfile uses multi-stage builds:

1. **Builder Stage**: Compiles application, builds assets
2. **Runner Stage**: Production runtime with minimal dependencies

### Building Custom Images

```bash
# Build OSS version with SQLite
docker build -t aether-edge:oss .

# Build Enterprise version with PostgreSQL
docker build --build-arg BUILD=enterprise --build-arg DATABASE=pg -t aether-edge:enterprise .

# Build specific stage
docker build --target runner -t aether-edge:prod .
```

## Production Architecture

### Services Overview

| Service | Image | Purpose | Ports |
|----------|-------|---------|-------|
| pangolin | fosrl/pangolin:latest | Main application | Internal |
| gerbil | fosrl/gerbil:latest | WireGuard gateway | 80, 443, 51820/udp, 21820/udp |
| traefik | traefik:v3.5 | Reverse proxy | 80, 443 |

### Network Configuration

- Custom bridge network named `pangolin`
- IPv6 enabled
- Traefik uses `network_mode: service:gerbil`

### Volume Structure

```
config/
├── config.yml              # Main configuration
├── traefik/
│   ├── traefik_config.yml   # Traefik static config
│   └── dynamic_config.yml   # Dynamic configuration
└── letsencrypt/            # SSL certificates
```

## Configuration Details

### Main Configuration (config/config.yml)

#### Application Settings
```yaml
app:
  dashboard_url: https://your-domain.com  # Public URL
  log_level: info                      # debug, info, warn, error
```

#### Domain Configuration
```yaml
domains:
  domain1:                           # Arbitrary key name
    base_domain: your-domain.com        # Your domain
```

#### Server Security
```yaml
server:
  secret: your-very-secure-secret-key    # Generate with: openssl rand -hex 32
```

#### Gerbil Configuration
```yaml
gerbil:
  base_endpoint: your-domain.com         # Base endpoint for tunnels
```

#### Organization Settings
```yaml
orgs:
  block_size: 24                       # VPN subnet block size
  subnet_group: 100.90.137.0/20       # VPN subnet range
```

#### Feature Flags
```yaml
flags:
  require_email_verification: true        # Require email verification
  disable_signup_without_invite: false    # Allow public signup
  disable_user_create_org: false        # Allow users to create orgs
  allow_raw_resources: false           # Allow raw TCP/UDP resources
  enable_integration_api: true          # Enable API integration
  enable_clients: true                 # Enable client management
```

### Traefik Configuration (config/traefik/traefik_config.yml)

#### API and Dashboard
```yaml
api:
  insecure: false                      # Set to true for local testing
  dashboard: true                      # Enable Traefik dashboard
```

#### File Provider
```yaml
providers:
  file:
    directory: "/var/dynamic"           # Dynamic config directory
    watch: true                        # Watch for changes
```

#### Plugins
```yaml
experimental:
  plugins:
    badger:
      moduleName: "github.com/fosrl/badger"
      version: "v1.2.0"
```

#### Logging
```yaml
log:
  level: "INFO"                       # DEBUG, INFO, WARN, ERROR
  format: "common"                    # json, common
  maxSize: 100                        # Max log size (MB)
  maxBackups: 3                       # Number of backup logs
  maxAge: 3                           # Days to retain logs
  compress: true                       # Compress old logs
```

#### Entry Points
```yaml
entryPoints:
  web:
    address: ":80"                     # HTTP entry point
  websecure:
    address: ":443"                    # HTTPS entry point
    transport:
      respondingTimeouts:
        readTimeout: "30m"              # Long timeout for tunnels
```

## Security Configuration

### SSL/TLS Setup

1. **Generate SSL Certificate**:
   ```bash
   # Let's Encrypt certificates are automatically generated
   # Ensure ports 80/443 are accessible
   ```

2. **Configure Domain**:
   ```yaml
   domains:
     main:
       base_domain: your-domain.com
   ```

### Security Best Practices

1. **Generate Strong Secret**:
   ```bash
   openssl rand -hex 32
   ```

2. **Firewall Configuration**:
   ```bash
   # Allow required ports
   ufw allow 80/tcp
   ufw allow 443/tcp
   ufw allow 51820/udp
   ufw allow 21820/udp
   ```

3. **Network Isolation**:
   - Use custom Docker networks
   - Limit container capabilities
   - Read-only filesystems where possible

## Database Configuration

### SQLite (Default)
- File-based database
- Good for small deployments
- No additional configuration needed

### PostgreSQL (Recommended for Production)
1. **Add PostgreSQL to docker-compose.yml**:
   ```yaml
   postgres:
     image: postgres:17
     environment:
       POSTGRES_DB: pangolin
       POSTGRES_USER: pangolin
       POSTGRES_PASSWORD: your-password
     volumes:
       - postgres_data:/var/lib/postgresql/data
     networks:
       - pangolin
   ```

2. **Update Application Config**:
   ```yaml
   database:
     url: postgresql://pangolin:your-password@postgres:5432/pangolin
   ```

3. **Build with PostgreSQL Support**:
   ```bash
   docker build --build-arg DATABASE=pg -t aether-edge:pg .
   ```

## Monitoring and Maintenance

### Health Checks

All services include health checks:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3001/api/v1/"]
  interval: "30s"
  timeout: "10s"
  retries: 3
  start_period: "40s"
```

### Log Management

Logs are configured for rotation:
- Application logs: Docker container logs
- Traefik logs: File-based with rotation
- Access logs: Configurable retention

### Backup Strategy

1. **Configuration Backup**:
   ```bash
   tar -czf config-backup-$(date +%Y%m%d).tar.gz config/
   ```

2. **Database Backup** (PostgreSQL):
   ```bash
   docker exec postgres pg_dump -U pangolin pangolin > backup.sql
   ```

3. **Automated Backup**:
   ```bash
   # Add to crontab
   0 2 * * * /path/to/backup-script.sh
   ```

## Performance Optimization

### Resource Limits

Configure resource limits in docker-compose.yml:
```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 2G
    reservations:
      cpus: '1.0'
      memory: 1G
```

### Caching

- Redis for session storage
- Application-level caching
- Static asset caching via Traefik

### Scaling

#### Horizontal Scaling
- Multiple Gerbil instances behind load balancer
- Database replication for PostgreSQL
- Shared storage for configuration

#### Vertical Scaling
- Increase CPU/memory allocation
- Optimize database queries
- Use SSD storage

## Troubleshooting

### Common Issues

1. **Container Won't Start**:
   ```bash
   # Check logs
   docker-compose logs pangolin
   
   # Check configuration
   docker-compose config
   ```

2. **SSL Certificate Issues**:
   ```bash
   # Check domain accessibility
   curl -I http://your-domain.com
   
   # Verify port 80 is open
   telnet your-domain.com 80
   ```

3. **WireGuard Connection Issues**:
   ```bash
   # Check UDP ports
   nmap -sU -p 51820,21820 your-domain.com
   
   # Check firewall rules
   iptables -L -n | grep 51820
   ```

### Debug Mode

Enable debug logging:
```yaml
app:
  log_level: debug
```

Traefik debug:
```yaml
log:
  level: "DEBUG"
```

## Advanced Configuration

### Custom Build

For custom builds with specific features:

```bash
# Build with custom arguments
docker build \
  --build-arg BUILD=enterprise \
  --build-arg DATABASE=pg \
  -t aether-edge:custom \
  .
```

### Environment Variables

Override configuration with environment variables:
```yaml
services:
  pangolin:
    environment:
      - APP_LOG_LEVEL=debug
      - SERVER_SECRET=your-secret
      - DOMAINS_DOMAIN1_BASE_DOMAIN=your-domain.com
```

### Custom Networks

```yaml
networks:
  frontend:
    driver: bridge
    internal: false
  backend:
    driver: bridge
    internal: true
```

## Migration Guide

### From Development to Production

1. **Export Development Data**:
   ```bash
   # SQLite
   docker exec dev_pangolin cp /app/data/database.db ./
   
   # PostgreSQL
   docker exec dev_postgres pg_dump -U postgres postgres > dev-data.sql
   ```

2. **Import to Production**:
   ```bash
   # SQLite
   docker cp database.db prod_pangolin:/app/data/
   
   # PostgreSQL
   docker exec -i prod_postgres psql -U pangolin pangolin < dev-data.sql
   ```

### Version Updates

1. **Backup Current Version**:
   ```bash
   docker-compose down
   tar -czf backup-$(date +%Y%m%d).tar.gz config/
   ```

2. **Update Images**:
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

3. **Run Migrations**:
   ```bash
   docker-compose exec pangolin npm run db:migrate
   ```

## Support and Documentation

- **Documentation**: https://docs.pangolin.net
- **Issues**: https://github.com/fosrl/pangolin/issues
- **Community**: https://github.com/fosrl/pangolin/discussions

## Production Checklist

Before going live, ensure:

- [ ] Domain configured and pointing to server
- [ ] SSL certificates generated
- [ ] Firewall ports open (80, 443, 51820/udp, 21820/udp)
- [ ] Strong secret key generated
- [ ] Database configured (PostgreSQL recommended)
- [ ] Backup strategy implemented
- [ ] Monitoring configured
- [ ] Log rotation configured
- [ ] Resource limits set
- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] Email verification configured
- [ ] Admin account created

This guide provides a comprehensive foundation for deploying Aether Edge in production. Adjust configurations based on your specific requirements and infrastructure.