# Installation Guide

This guide will help you install and set up Aether Edge on your system. Aether Edge can be deployed using Docker, installed from source, or run using pre-built binaries.

## Prerequisites

### System Requirements

- **Operating System**: Linux, macOS, or Windows
- **Memory**: Minimum 2GB RAM, 4GB+ recommended
- **Storage**: Minimum 10GB free space
- **Network**: Administrative access to configure networking

### Software Requirements

- **Node.js**: Version 18.0 or higher
- **npm**: Version 8.0 or higher (comes with Node.js)
- **Docker**: Version 20.10+ (for Docker deployment)
- **Docker Compose**: Version 2.0+ (for Docker deployment)
- **WireGuard®**: For tunnel management (optional, for advanced configurations)

## Installation Methods

### Method 1: Docker Deployment (Recommended)

Docker is the recommended installation method as it provides a consistent environment and simplifies dependency management.

#### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/fosrl/pangolin.git
   cd pangolin
   ```

2. **Configure environment**
   ```bash
   cp config/config.example.yml config/config.yml
   # Edit config.yml with your settings
   ```

3. **Start with Docker Compose**
   ```bash
   docker-compose up -d
   ```

4. **Access the application**
   - Dashboard: http://localhost:3002
   - API: http://localhost:3000

#### Docker Compose Configuration

The `docker-compose.yml` file includes the following services:

- **app**: Main application server
- **database**: PostgreSQL (optional, can use SQLite)
- **traefik**: Reverse proxy (optional)

#### Environment Variables

Create a `.env` file for Docker-specific configurations:

```bash
# Database Configuration
DATABASE_URL=postgresql://user:password@database:5432/pangolin

# Application Configuration
NODE_ENV=production
ENVIRONMENT=prod

# Security
SERVER_SECRET=your-secret-key-here

# External Services
REDIS_URL=redis://redis:6379
```

### Method 2: Source Installation

For development or custom deployments, you can install from source.

#### Step 1: Clone and Setup

```bash
git clone https://github.com/fosrl/pangolin.git
cd pangolin
```

#### Step 2: Install Dependencies

```bash
npm install
```

#### Step 3: Configure Application

```bash
# Copy configuration template
cp config/config.example.yml config/config.yml

# Edit the configuration file
nano config/config.yml
```

#### Step 4: Database Setup

**For SQLite (Default):**
```bash
npm run set:sqlite
npm run db:sqlite:push
```

**For PostgreSQL:**
```bash
npm run set:pg
npm run db:pg:push
```

#### Step 5: Build Application

```bash
# Set build variant (oss, enterprise, or saas)
npm run set:oss

# Build for production
npm run build:sqlite  # or npm run build:pg for PostgreSQL
```

#### Step 6: Start Application

```bash
npm start
```

### Method 3: Binary Installation

Pre-built binaries are available for quick deployment without Node.js dependencies.

#### Download Binary

```bash
# Download the latest release
wget https://github.com/fosrl/pangolin/releases/latest/download/pangolin-linux-amd64.tar.gz

# Extract
tar -xzf pangolin-linux-amd64.tar.gz
cd pangolin
```

#### Configure and Run

```bash
# Create configuration directory
mkdir -p config

# Copy and edit configuration
cp config.example.yml config/config.yml
nano config/config.yml

# Run the application
./pangolin
```

## Configuration

### Basic Configuration

Edit `config/config.yml` to configure your instance:

```yaml
app:
  dashboard_url: http://localhost:3002
  log_level: info

domains:
  main:
    base_domain: yourdomain.com

server:
  secret: your-secret-key-here

orgs:
  block_size: 24
  subnet_group: 100.90.137.0/20

flags:
  require_email_verification: false
  disable_signup_without_invite: false
  disable_user_create_org: false
```

### Database Configuration

#### SQLite Configuration

```yaml
database:
  type: sqlite
  path: ./data/pangolin.db
```

#### PostgreSQL Configuration

```yaml
database:
  type: postgresql
  host: localhost
  port: 5432
  database: pangolin
  username: pangolin
  password: your-password
```

### Security Configuration

```yaml
server:
  secret: your-very-secure-secret-key
  session_timeout: 24h

auth:
  require_mfa: false
  password_min_length: 8
  session_secure: true
```

## Post-Installation Setup

### 1. Create Admin User

After starting the application, create your first admin user:

```bash
# Using the CLI
npm run cli create-admin --email admin@example.com --password your-password
```

Or through the web interface at http://localhost:3002

### 2. Configure Domains

Add your domains to the configuration:

```yaml
domains:
  main:
    base_domain: example.com
    ssl:
      enabled: true
      email: admin@example.com
```

### 3. Set Up WireGuard®

Configure WireGuard® for secure tunneling:

```bash
# Generate keys
wg genkey | tee privatekey | wg pubkey > publickey

# Add to configuration
wireguard:
  private_key_path: /path/to/privatekey
  public_key: "your-public-key-here"
  listen_port: 51820
```

### 4. Configure Email (Optional)

For email notifications and user verification:

```yaml
email:
  provider: smtp
  smtp:
    host: smtp.gmail.com
    port: 587
    secure: false
    auth:
      user: your-email@gmail.com
      pass: your-app-password
```

## Verification

### Health Checks

Verify your installation:

```bash
# Check API health
curl http://localhost:3000/health

# Check dashboard
curl http://localhost:3002
```

### Service Status

Check that all services are running:

```bash
# For Docker deployment
docker-compose ps

# For source installation
ps aux | grep pangolin
```

## Troubleshooting

### Common Issues

#### Port Conflicts

If ports are already in use, modify the configuration:

```yaml
app:
  dashboard_url: http://localhost:3003  # Change port
```

#### Database Connection Issues

For PostgreSQL connection problems:

1. Verify database is running
2. Check connection string
3. Ensure firewall allows connection
4. Verify user permissions

#### Permission Issues

Ensure the application has write permissions:

```bash
# For data directory
chmod 755 ./data
chown $USER:$USER ./data

# For logs
chmod 755 ./logs
chown $USER:$USER ./logs
```

### Log Files

Check logs for debugging:

```bash
# Application logs
tail -f logs/app.log

# Error logs
tail -f logs/error.log

# Docker logs
docker-compose logs -f app
```

### Getting Help

If you encounter issues:

1. Check the [troubleshooting guide](https://docs.pangolin.net/troubleshooting)
2. Search [GitHub Issues](https://github.com/fosrl/pangolin/issues)
3. Join our [Discord Community](https://discord.gg/pangolin)
4. Contact [support](mailto:support@pangolin.net)

## Next Steps

After successful installation:

1. [Configure your first site](docs/site-configuration.md)
2. [Set up users and organizations](docs/user-management.md)
3. [Create proxy resources](docs/resource-management.md)
4. [Configure monitoring](docs/monitoring.md)

## Upgrading

To upgrade Aether Edge:

### Docker Deployment

```bash
# Pull latest images
docker-compose pull

# Restart services
docker-compose up -d
```

### Source Installation

```bash
# Update repository
git pull origin main

# Install new dependencies
npm install

# Rebuild application
npm run build:sqlite

# Restart service
npm start
```

### Database Migrations

Always run database migrations after upgrading:

```bash
# SQLite
npm run db:sqlite:push

# PostgreSQL
npm run db:pg:push
```