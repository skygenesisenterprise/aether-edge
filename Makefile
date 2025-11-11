.PHONY: build build-pg build-release build-arm build-x86 test clean help build-oss build-saas build-enterprise build-local deploy-prod env-setup

major_tag := $(shell echo $(tag) | cut -d. -f1)
minor_tag := $(shell echo $(tag) | cut -d. -f1,2)
build-release:
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make build-release tag=<tag>"; \
		exit 1; \
	fi
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=sqlite \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:latest \
		--tag fosrl/pangolin:$(major_tag) \
		--tag fosrl/pangolin:$(minor_tag) \
		--tag fosrl/pangolin:$(tag) \
		--push .
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=pg \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:postgresql-latest \
		--tag fosrl/pangolin:postgresql-$(major_tag) \
		--tag fosrl/pangolin:postgresql-$(minor_tag) \
		--tag fosrl/pangolin:postgresql-$(tag) \
		--push .
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=sqlite \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:ee-latest \
		--tag fosrl/pangolin:ee-$(major_tag) \
		--tag fosrl/pangolin:ee-$(minor_tag) \
		--tag fosrl/pangolin:ee-$(tag) \
		--push .
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=pg \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:ee-postgresql-latest \
		--tag fosrl/pangolin:ee-postgresql-$(major_tag) \
		--tag fosrl/pangolin:ee-postgresql-$(minor_tag) \
		--tag fosrl/pangolin:ee-postgresql-$(tag) \
		--push .

build-rc:
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make build-release tag=<tag>"; \
		exit 1; \
	fi
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=sqlite \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:$(tag) \
		--push .
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=pg \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:postgresql-$(tag) \
		--push .
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=sqlite \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:ee-$(tag) \
		--push .
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=pg \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:ee-postgresql-$(tag) \
		--push .

build-arm:
	docker buildx build --platform linux/arm64 -t fosrl/pangolin:latest .

build-x86:
	docker buildx build --platform linux/amd64 -t fosrl/pangolin:latest .

build-sqlite:
	docker build --build-arg DATABASE=sqlite -t fosrl/pangolin:latest .

build-pg:
	docker build --build-arg DATABASE=pg -t fosrl/pangolin:postgresql-latest .

test:
	docker run -it -p 3000:3000 -p 3001:3001 -p 3002:3002 -v ./config:/app/config fosrl/pangolin:latest

clean:
	docker rmi pangolin

# Help target
help:
	@echo "Aether Edge Build and Deployment"
	@echo ""
	@echo "Available targets:"
	@echo "  build-oss        - Build OSS version with SQLite"
	@echo "  build-saas       - Build SaaS version with SQLite"
	@echo "  build-enterprise - Build Enterprise version with PostgreSQL"
	@echo "  build-local       - Build with custom environment variables"
	@echo "  deploy-prod      - Deploy production environment"
	@echo "  env-setup        - Setup environment files"
	@echo "  build-release     - Build and push release (existing)"
	@echo "  build-rc         - Build and push release candidate"
	@echo "  build-arm         - Build for ARM architecture"
	@echo "  build-x86         - Build for x86 architecture"
	@echo "  build-sqlite      - Build with SQLite"
	@echo "  build-pg          - Build with PostgreSQL"
	@echo "  test             - Test container"
	@echo "  clean            - Clean Docker resources"
	@echo ""
	@echo "Environment variables for build-local:"
	@echo "  BUILD_TYPE        - oss, saas, or enterprise"
	@echo "  DATABASE_TYPE     - sqlite or pg"
	@echo "  IMAGE_TAG        - Docker image tag"
	@echo "  REGISTRY_URL      - Registry URL for pushing"
	@echo ""
	@echo "Examples:"
	@echo "  make build-enterprise"
	@echo "  make build-local BUILD_TYPE=enterprise DATABASE_TYPE=pg"
	@echo "  make env-setup"

# Environment setup
env-setup:
	@echo "Setting up environment files..."
	@if [ ! -f .env.production ]; then \
		cp .env.production.example .env.production 2>/dev/null || echo "Creating .env.production..."; \
	fi
	@if [ ! -f .env ]; then \
		cp .env.example .env 2>/dev/null || echo "Creating .env..."; \
	fi
	@echo "Environment files ready!"

# Local build with environment variables
build-local:
	@if [ -z "$(BUILD_TYPE)" ] || [ -z "$(DATABASE_TYPE)" ]; then \
		echo "Error: BUILD_TYPE and DATABASE_TYPE must be set"; \
		echo "Usage: make build-local BUILD_TYPE=oss|saas|enterprise DATABASE_TYPE=sqlite|pg"; \
		exit 1; \
	fi
	@echo "Building locally: $(BUILD_TYPE) with $(DATABASE_TYPE)"
	docker build \
		--build-arg BUILD=$(BUILD_TYPE) \
		--build-arg DATABASE=$(DATABASE_TYPE) \
		-t aether-edge:$(IMAGE_TAG)-local \
		.

# Build variants
build-oss:
	@echo "Building OSS version with SQLite..."
	docker build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=sqlite \
		-t aether-edge:oss-latest \
		.

build-saas:
	@echo "Building SaaS version with SQLite..."
	docker build \
		--build-arg BUILD=saas \
		--build-arg DATABASE=sqlite \
		-t aether-edge:saas-latest \
		.

build-enterprise:
	@echo "Building Enterprise version with PostgreSQL..."
	docker build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=pg \
		-t aether-edge:enterprise-latest \
		.

# Production deployment
deploy-prod:
	@echo "Deploying production environment..."
	@if [ ! -f .env.production ]; then \
		echo "Error: .env.production file not found. Run 'make env-setup' first."; \
		exit 1; \
	fi
	./deploy.sh

# Quick development setup
dev-setup: env-setup
	@echo "Setting up development environment..."
	docker-compose up -d postgres redis
	@echo "Development environment ready!"

# Build with custom arguments
build-custom:
	@if [ -z "$(BUILD_ARGS)" ]; then \
		echo "Usage: make build-custom BUILD_ARGS='--build-arg VAR=value'"; \
		exit 1; \
	fi
	docker build $(BUILD_ARGS) -t aether-edge:custom .
