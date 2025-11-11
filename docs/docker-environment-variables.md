# Docker Environment Variables Guide for Aether Edge

## Overview

Aether Edge supports flexible configuration through Docker build arguments and environment variables. This guide explains how to use them effectively.

## Docker File Information

| Field | Value |
|--------|-------|
| **Docker File Path** | `./Dockerfile` (or `./Dockerfile.production` for production) |
| **Docker Context Path** | `.` (project root) |
| **Docker Build Stage** | `runner` (production stage) or `builder` (development stage) |

## Build Arguments (ARG)

Build arguments are set during the Docker build process and determine the application variant.

### Available Build Arguments

| Argument | Values | Default | Description |
|----------|---------|----------|-------------|
| `BUILD` | `oss`, `saas`, `enterprise` | `oss` | Build variant to compile |
| `DATABASE` | `sqlite`, `pg` | `sqlite` | Database backend to use |
| `NODE_ENV` | `development`, `production` | `production` | Node.js environment |

### Using Build Arguments

#### Method 1: Docker Build Command
```bash
# Build Enterprise version with PostgreSQL
docker build \
  --build-arg BUILD=enterprise \
  --build-arg DATABASE=pg \
  -t aether-edge:enterprise-pg \
  .

# Build SaaS version with SQLite
docker build \
  --build-arg BUILD=saas \
  --build-arg DATABASE=sqlite \
  -t aether-edge:saas-sqlite \
  .
```

#### Method 2: Docker Compose
```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        BUILD: enterprise
        DATABASE: pg
```

#### Method 3: Using the Build Script
```bash
# Using the build script
./build.sh --type enterprise --database pg --tag v1.0.0

# Using Makefile
make build-enterprise
make build-local BUILD_TYPE=enterprise DATABASE_TYPE=pg
```

## Environment Variables

Environment variables configure the running application.

### Configuration Files

1. **Development**: `.env`
2. **Production**: `.env.production`

### Key Environment Variables

#### Security
```bash
SERVER_SECRET=your-secure-secret-key
POSTGRES_PASSWORD=database-password
SESSION_SECRET=session-encryption-key
```

#### Domain Configuration
```bash
DASHBOARD_URL=https://your-domain.com
DOMAIN_NAME=your-domain.com
ACME_EMAIL=admin@your-domain.com
```

#### Feature Flags
```bash
REQUIRE_EMAIL_VERIFICATION=true
DISABLE_SIGNUP_WITHOUT_INVITE=false
DISABLE_USER_CREATE_ORG=false
ALLOW_RAW_RESOURCES=false
ENABLE_INTEGRATION_API=true
ENABLE_CLIENTS=true
```

#### Performance
```bash
LOG_LEVEL=info
NODE_OPTIONS=--max-old-space-size=4096
DB_POOL_MAX=10
CACHE_TTL=3600
```

## TypeScript Configuration Selection

The Dockerfile automatically selects the appropriate TypeScript configuration based on the `BUILD` argument:

```dockerfile
# This logic in Dockerfile copies the right config:
RUN if [ "$BUILD" = "oss" ]; then 
    cp tsconfig.oss.json tsconfig.json; \
  elif [ "$BUILD" = "saas" ]; then 
    cp tsconfig.saas.json tsconfig.json; \
  elif [ "$BUILD" = "enterprise" ]; then 
    cp tsconfig.enterprise.json tsconfig.json; \
  fi
```

### TypeScript Configurations Available

| Build Type | Config File | Features |
|------------|-------------|----------|
| `oss` | `tsconfig.oss.json` | Open Source features only |
| `saas` | `tsconfig.saas.json` | SaaS-specific features |
| `enterprise` | `tsconfig.enterprise.json` | Full feature set |

## Database Configuration

### SQLite (Default)
- No additional configuration required
- File-based storage
- Good for small deployments

### PostgreSQL (Recommended for Production)
```bash
# Build with PostgreSQL support
docker build --build-arg DATABASE=pg -t aether-edge:pg .

# Environment variables for PostgreSQL
DATABASE_URL=postgresql://user:password@host:5432/database
DB_POOL_MIN=2
DB_POOL_MAX=10
DB_CONNECTION_TIMEOUT=30000
```

## Build Variants

### OSS (Open Source)
```bash
# Build OSS version
docker build \
  --build-arg BUILD=oss \
  --build-arg DATABASE=sqlite \
  -t aether-edge:oss \
  .

# Features:
- Core tunneling functionality
- Basic user management
- SQLite database
- No private features
```

### SaaS
```bash
# Build SaaS version
docker build \
  --build-arg BUILD=saas \
  --build-arg DATABASE=sqlite \
  -t aether-edge:saas \
  .

# Features:
- Multi-tenant support
- Billing integration
- Enhanced user management
- SaaS-specific optimizations
```

### Enterprise
```bash
# Build Enterprise version
docker build \
  --build-arg BUILD=enterprise \
  --build-arg DATABASE=pg \
  -t aether-edge:enterprise \
  .

# Features:
- All OSS features
- Private modules included
- Advanced security features
- Enterprise integrations
- PostgreSQL support
```

## Multi-Stage Build

The Dockerfile uses multi-stage builds:

### Stage 1: Builder
```dockerfile
FROM node:22-alpine AS builder
ARG BUILD=oss
ARG DATABASE=sqlite
# Installs dependencies, builds application, generates migrations
```

### Stage 2: Runner
```dockerfile
FROM node:22-alpine AS runner
# Production runtime with minimal dependencies
# Copies artifacts from builder stage
```

### Targeting Specific Stages
```bash
# Build only the builder stage (for debugging)
docker build --target builder -t aether-edge:builder .

# Build only the runner stage (production)
docker build --target runner -t aether-edge:production .
```

## Production Deployment

### Quick Start
```bash
# 1. Setup environment
make env-setup

# 2. Edit .env.production with your values
# Edit configuration files

# 3. Deploy
make deploy-prod

# Or manually:
./deploy.sh
```

### Custom Production Build
```bash
# Build custom production variant
docker build \
  --build-arg BUILD=enterprise \
  --build-arg DATABASE=pg \
  --build-arg NODE_ENV=production \
  -f Dockerfile.production \
  -t aether-edge:custom-prod \
  .
```

## Development Workflow

### Local Development
```bash
# Development build with hot reload
docker-compose up -d

# Or build specific variant for development
docker build \
  --build-arg BUILD=enterprise \
  --build-arg DATABASE=pg \
  -t aether-edge:dev \
  .
```

### Testing Different Variants
```bash
# Test OSS version
make build-oss
docker run -p 3000:3000 aether-edge:oss-latest

# Test Enterprise version
make build-enterprise
docker run -p 3000:3000 aether-edge:enterprise-latest
```

## Advanced Configuration

### Custom Build Arguments
You can extend the Dockerfile to support custom build arguments:

```dockerfile
ARG CUSTOM_FEATURE=false
RUN if [ "$CUSTOM_FEATURE" = "true" ]; then \
    echo "Enabling custom feature"; \
  fi
```

### Environment-Specific Builds
```bash
# Development build
docker build \
  --build-arg BUILD=enterprise \
  --build-arg DATABASE=pg \
  --build-arg NODE_ENV=development \
  -t aether-edge:dev \
  .

# Production build
docker build \
  --build-arg BUILD=enterprise \
  --build-arg DATABASE=pg \
  --build-arg NODE_ENV=production \
  -t aether-edge:prod \
  .
```

## Troubleshooting

### Build Issues
```bash
# Check build arguments
docker build --no-cache --build-arg BUILD=oss . 2>&1 | grep -i error

# Verify TypeScript config was copied
docker run --rm aether-edge:oss ls -la tsconfig.json
```

### Runtime Issues
```bash
# Check environment variables
docker run --rm aether-edge:enterprise env | grep -E "(BUILD|DATABASE|SERVER)"

# Check which features are enabled
docker logs aether-edge-container | grep -i "build type\|database"
```

### Configuration Validation
```bash
# Validate configuration before deployment
./deploy.sh validate
./deploy.sh dry-run
```

## Best Practices

1. **Use Specific Tags**: Always tag images with version numbers
2. **Secure Secrets**: Generate unique secrets for each deployment
3. **Environment Separation**: Use different configs for dev/staging/prod
4. **Multi-Stage Builds**: Use multi-stage builds for smaller production images
5. **Build Arguments**: Use build arguments for compile-time configuration
6. **Environment Variables**: Use environment variables for runtime configuration

## Examples

### Complete Production Setup
```bash
# 1. Clone and setup
git clone https://github.com/fosrl/pangolin.git
cd pangolin
make env-setup

# 2. Configure environment
cp .env.production.example .env.production
# Edit .env.production with your values

# 3. Build and deploy
docker build \
  --build-arg BUILD=enterprise \
  --build-arg DATABASE=pg \
  -f Dockerfile.production \
  -t my-registry/aether-edge:v1.0.0 \
  .

docker-compose --env-file .env.production -f docker-compose.production.yml up -d
```

### Development Workflow
```bash
# Development cycle
make build-enterprise
docker-compose up -d
make logs
# Make changes
make build-enterprise
docker-compose up -d --force-recreate
```

This system provides maximum flexibility for deploying Aether Edge in different environments with different feature sets and configurations.