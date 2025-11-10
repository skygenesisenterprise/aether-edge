# Deployment Guide

This guide covers various deployment strategies for Aether Edge, from small single-server deployments to large-scale distributed installations.

## Deployment Overview

Aether Edge can be deployed in several ways:

- **Docker Deployment** - Recommended for most use cases
- **Binary Deployment** - Direct installation on servers
- **Kubernetes Deployment** - For cloud-native environments
- **Cloud Platform Deployment** - AWS, GCP, Azure deployments

## Production Requirements

### Minimum Requirements

- **CPU**: 2 cores
- **Memory**: 4GB RAM
- **Storage**: 20GB SSD
- **Network**: 100Mbps+ connection
- **OS**: Linux (Ubuntu 20.04+, CentOS 8+, RHEL 8+)

### Recommended Requirements

- **CPU**: 4+ cores
- **Memory**: 8GB+ RAM
- **Storage**: 50GB+ SSD
- **Network**: 1Gbps+ connection
- **Load Balancer**: For high availability

### Database Requirements

#### SQLite (Small Deployments)
- **Storage**: 10GB+ for database growth
- **Backup**: Regular file backups required

#### PostgreSQL (Production)
- **CPU**: 2+ cores
- **Memory**: 4GB+ RAM
- **Storage**: 50GB+ SSD
- **Connection Pooling**: Recommended

## Docker Deployment

### Single Server Deployment

#### 1. Prepare Environment

```bash
# Create deployment directory
mkdir -p /opt/pangolin
cd /opt/pangolin

# Clone repository
git clone https://github.com/fosrl/pangolin.git .

# Create environment file
cat > .env << EOF
NODE_ENV=production
ENVIRONMENT=prod
SERVER_SECRET=$(openssl rand -hex 32)
DATABASE_URL=postgresql://pangolin:password@postgres:5432/pangolin
EOF
```

#### 2. Configure Application

```bash
# Copy configuration template
cp config/config.example.yml config/config.yml

# Edit configuration
nano config/config.yml
```

Production configuration example:

```yaml
app:
  dashboard_url: https://pangolin.example.com
  log_level: info

domains:
  main:
    base_domain: example.com

server:
  secret: ${SERVER_SECRET}
  external_port: 443
  trust_proxy: true

database:
  type: postgresql
  host: postgres
  port: 5432
  database: pangolin
  username: pangolin
  password: password

orgs:
  block_size: 24
  subnet_group: 100.90.137.0/20

flags:
  require_email_verification: true
  disable_signup_without_invite: true
  disable_user_create_org: true
```

#### 3. Docker Compose Configuration

Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  app:
    image: fosrl/pangolin:latest
    container_name: pangolin_app
    restart: unless-stopped
    ports:
      - "3000:3000"
      - "3001:3001"
      - "3002:3002"
    environment:
      - NODE_ENV=production
      - ENVIRONMENT=prod
      - DATABASE_URL=postgresql://pangolin:${DB_PASSWORD}@postgres:5432/pangolin
      - SERVER_SECRET=${SERVER_SECRET}
    volumes:
      - ./config:/app/config:ro
      - ./data:/app/data
      - ./logs:/app/logs
    depends_on:
      - postgres
      - redis
    networks:
      - pangolin-network

  postgres:
    image: postgres:15-alpine
    container_name: pangolin_postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=pangolin
      - POSTGRES_USER=pangolin
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    networks:
      - pangolin-network

  redis:
    image: redis:7-alpine
    container_name: pangolin_redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - pangolin-network

  traefik:
    image: traefik:v3.0
    container_name: pangolin_traefik
    restart: unless-stopped
    command:
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencrypt.acme.email=admin@example.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./letsencrypt:/letsencrypt
    networks:
      - pangolin-network

volumes:
  postgres_data:
  redis_data:

networks:
  pangolin-network:
    driver: bridge
```

#### 4. Deploy Application

```bash
# Set environment variables
export SERVER_SECRET=$(openssl rand -hex 32)
export DB_PASSWORD=$(openssl rand -base64 32)

# Start services
docker-compose -f docker-compose.prod.yml up -d

# Initialize database
docker-compose -f docker-compose.prod.yml exec app npm run db:pg:push

# Check status
docker-compose -f docker-compose.prod.yml ps
```

### Multi-Server Deployment

#### Load Balancer Configuration

Nginx configuration example:

```nginx
upstream pangolin_api {
    server 10.0.1.10:3000;
    server 10.0.1.11:3000;
    server 10.0.1.12:3000;
}

upstream pangolin_dashboard {
    server 10.0.1.10:3002;
    server 10.0.1.11:3002;
    server 10.0.1.12:3002;
}

server {
    listen 80;
    server_name pangolin.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name pangolin.example.com;

    ssl_certificate /etc/ssl/certs/pangolin.crt;
    ssl_certificate_key /etc/ssl/private/pangolin.key;

    location /api/ {
        proxy_pass http://pangolin_api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        proxy_pass http://pangolin_dashboard;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Kubernetes Deployment

### 1. Namespace and ConfigMaps

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: pangolin

---
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pangolin-config
  namespace: pangolin
data:
  config.yml: |
    app:
      dashboard_url: https://pangolin.example.com
      log_level: info
    
    domains:
      main:
        base_domain: example.com
    
    server:
      secret: "${SERVER_SECRET}"
    
    orgs:
      block_size: 24
      subnet_group: 100.90.137.0/20
```

### 2. Secrets

```yaml
# secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: pangolin-secrets
  namespace: pangolin
type: Opaque
data:
  server-secret: <base64-encoded-secret>
  db-password: <base64-encoded-password>
```

### 3. Deployment

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pangolin
  namespace: pangolin
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pangolin
  template:
    metadata:
      labels:
        app: pangolin
    spec:
      containers:
      - name: pangolin
        image: fosrl/pangolin:latest
        ports:
        - containerPort: 3000
        - containerPort: 3002
        env:
        - name: NODE_ENV
          value: "production"
        - name: ENVIRONMENT
          value: "prod"
        - name: SERVER_SECRET
          valueFrom:
            secretKeyRef:
              name: pangolin-secrets
              key: server-secret
        - name: DATABASE_URL
          value: "postgresql://pangolin:$(DB_PASSWORD)@postgres:5432/pangolin"
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: pangolin-secrets
              key: db-password
        volumeMounts:
        - name: config
          mountPath: /app/config
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
      volumes:
      - name: config
        configMap:
          name: pangolin-config
```

### 4. Service and Ingress

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: pangolin-service
  namespace: pangolin
spec:
  selector:
    app: pangolin
  ports:
  - name: api
    port: 3000
    targetPort: 3000
  - name: dashboard
    port: 3002
    targetPort: 3002

---
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pangolin-ingress
  namespace: pangolin
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - pangolin.example.com
    secretName: pangolin-tls
  rules:
  - host: pangolin.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: pangolin-service
            port:
              number: 3000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: pangolin-service
            port:
              number: 3002
```

## Cloud Platform Deployment

### AWS Deployment

#### 1. ECS Task Definition

```json
{
  "family": "pangolin",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "executionRoleArn": "arn:aws:iam::account:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::account:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "pangolin",
      "image": "fosrl/pangolin:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        },
        {
          "containerPort": 3002,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ],
      "secrets": [
        {
          "name": "SERVER_SECRET",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:pangolin/server-secret"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/pangolin",
          "awslogs-region": "us-west-2",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

#### 2. Terraform Configuration

```hcl
# main.tf
provider "aws" {
  region = var.aws_region
}

# ECS Cluster
resource "aws_ecs_cluster" "pangolin" {
  name = "pangolin-cluster"
}

# Application Load Balancer
resource "aws_lb" "pangolin" {
  name               = "pangolin-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

# RDS PostgreSQL
resource "aws_db_instance" "pangolin" {
  identifier     = "pangolin-db"
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true
  
  db_name  = "pangolin"
  username = "pangolin"
  password = random_password.db_password.result
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.pangolin.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
}

# ECS Service
resource "aws_ecs_service" "pangolin" {
  name            = "pangolin-service"
  cluster         = aws_ecs_cluster.pangolin.id
  task_definition = aws_ecs_task_definition.pangolin.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.pangolin.arn
    container_name   = "pangolin"
    container_port   = 3002
  }
}
```

### Google Cloud Platform Deployment

#### Cloud Run Service

```yaml
# service.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: pangolin
  annotations:
    run.googleapis.com/ingress: all
spec:
  template:
    metadata:
      annotations:
        run.googleapis.com/cpu-throttling: "false"
        run.googleapis.com/memory: "2Gi"
    spec:
      containerConcurrency: 100
      timeoutSeconds: 300
      containers:
      - image: fosrl/pangolin:latest
        ports:
        - containerPort: 3002
        env:
        - name: NODE_ENV
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: pangolin-secrets
              key: database-url
        resources:
          limits:
            cpu: "1000m"
            memory: "2Gi"
```

## Monitoring and Logging

### 1. Application Monitoring

#### Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'pangolin'
    static_configs:
      - targets: ['pangolin-app:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s
```

#### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "Aether Edge Monitoring",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{status}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      }
    ]
  }
}
```

### 2. Log Management

#### ELK Stack Configuration

```yaml
# logstash.conf
input {
  beats {
    port => 5044
  }
}

filter {
  if [fields][service] == "pangolin" {
    json {
      source => "message"
    }
    
    date {
      match => [ "timestamp", "ISO8601" ]
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "pangolin-%{+YYYY.MM.dd}"
  }
}
```

## Backup and Recovery

### 1. Database Backups

#### PostgreSQL Backup Script

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="pangolin"
DB_USER="pangolin"

# Create backup
docker exec pangolin_postgres pg_dump -U $DB_USER $DB_NAME | gzip > $BACKUP_DIR/pangolin_$DATE.sql.gz

# Remove old backups (keep 30 days)
find $BACKUP_DIR -name "pangolin_*.sql.gz" -mtime +30 -delete

echo "Backup completed: pangolin_$DATE.sql.gz"
```

#### Automated Backups with Cron

```bash
# Add to crontab
0 2 * * * /opt/pangolin/scripts/backup.sh
```

### 2. Application Data Backup

```bash
#!/bin/bash
# backup-app-data.sh

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup configuration
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /opt/pangolin/config

# Backup application data
tar -czf $BACKUP_DIR/data_$DATE.tar.gz /opt/pangolin/data

# Backup logs (last 7 days)
find /opt/pangolin/logs -name "*.log" -mtime -7 -exec tar -czf $BACKUP_DIR/logs_$DATE.tar.gz {} +

echo "Application backup completed"
```

## Security Hardening

### 1. Network Security

#### Firewall Configuration

```bash
# UFW configuration
ufw default deny incoming
ufw default allow outgoing

# Allow SSH
ufw allow ssh

# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Allow WireGuard
ufw allow 51820/udp

# Enable firewall
ufw enable
```

#### SSL/TLS Configuration

```yaml
# traefik.yml
certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@example.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

### 2. Application Security

#### Environment Variables

```bash
# Secure environment setup
export NODE_ENV=production
export ENVIRONMENT=prod

# Generate secure secrets
export SERVER_SECRET=$(openssl rand -hex 32)
export JWT_SECRET=$(openssl rand -hex 32)
export SESSION_SECRET=$(openssl rand -hex 32)
```

#### Security Headers

```typescript
// security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));
```

## Performance Optimization

### 1. Database Optimization

#### PostgreSQL Configuration

```sql
-- postgresql.conf optimizations
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
```

#### Database Indexes

```sql
-- Add indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_sites_org_id ON sites(org_id);
CREATE INDEX idx_resources_site_id ON resources(site_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
```

### 2. Application Caching

#### Redis Configuration

```yaml
# redis.conf
maxmemory 512mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
```

#### Application Cache Implementation

```typescript
// cache service
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

export const cacheService = {
  async get<T>(key: string): Promise<T | null> {
    const value = await redis.get(key);
    return value ? JSON.parse(value) : null;
  },
  
  async set(key: string, value: any, ttl: number = 3600): Promise<void> {
    await redis.setex(key, ttl, JSON.stringify(value));
  },
  
  async del(key: string): Promise<void> {
    await redis.del(key);
  }
};
```

## Troubleshooting

### Common Issues

#### 1. Database Connection Issues

```bash
# Check PostgreSQL status
docker exec pangolin_postgres pg_isready

# Check connection logs
docker logs pangolin_postgres

# Test connection from app container
docker exec pangolin_app npm run db:test-connection
```

#### 2. Performance Issues

```bash
# Check resource usage
docker stats pangolin_app

# Monitor database queries
docker exec pangolin_postgres psql -U pangolin -c "SELECT * FROM pg_stat_activity;"

# Check application logs
docker logs pangolin_app --tail 100
```

#### 3. Network Issues

```bash
# Check port availability
netstat -tlnp | grep :3000

# Test connectivity
curl -I http://localhost:3000/health

# Check firewall rules
ufw status verbose
```

### Health Checks

#### Application Health Endpoint

```typescript
// health check route
app.get('/health', async (req, res) => {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    database: await checkDatabaseHealth(),
    redis: await checkRedisHealth()
  };
  
  res.json(health);
});
```

#### Kubernetes Health Checks

```yaml
# health checks in deployment
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Scaling Considerations

### Horizontal Scaling

- Load balancer configuration
- Session affinity considerations
- Database connection pooling
- Cache invalidation strategies

### Vertical Scaling

- Resource allocation optimization
- Memory usage monitoring
- CPU utilization tracking
- Storage capacity planning

This deployment guide provides comprehensive coverage of production deployment strategies for Aether Edge. Choose the deployment method that best fits your infrastructure requirements and scale.