# Data Warehouse Stack Management
# Makefile for easy docker-compose management

.PHONY: help build up down restart logs clean status

# Default target
help: ## Show this help message
	@echo "Data Warehouse Stack Management"
	@echo "=============================="
	@echo ""
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Data Warehouse Stack
dw-up: ## Start data warehouse stack only
	docker-compose -f docker-compose.dw.yml up -d

dw-down: ## Stop data warehouse stack
	docker-compose -f docker-compose.dw.yml down

dw-logs: ## Show data warehouse logs
	docker-compose -f docker-compose.dw.yml logs -f

# Monitoring Stack
monitoring-up: ## Start monitoring stack only
	docker-compose -f docker-compose.monitoring.yml up -d

monitoring-down: ## Stop monitoring stack
	docker-compose -f docker-compose.monitoring.yml down

monitoring-logs: ## Show monitoring logs
	docker-compose -f docker-compose.monitoring.yml logs -f

# Mage AI Stack
mage-up: ## Start Mage AI stack only
	docker-compose -f docker-compose.mage.yml up -d

mage-down: ## Stop Mage AI stack
	docker-compose -f docker-compose.mage.yml down

mage-logs: ## Show Mage AI logs
	docker-compose -f docker-compose.mage.yml logs -f

mage-restart: ## Restart Mage AI stack
	docker-compose -f docker-compose.mage.yml restart

mage-build: ## Build custom Mage AI image
	cd mage && docker-compose -f docker-compose.mage.yml build

# Full Stack
up: ## Start all stacks (data warehouse, monitoring, and Mage AI)
	docker-compose -f docker-compose.dw.yml up -d
	docker-compose -f docker-compose.monitoring.yml up -d
	docker-compose -f docker-compose.mage.yml up -d

down: ## Stop all stacks
	docker-compose -f docker-compose.dw.yml down
	docker-compose -f docker-compose.monitoring.yml down
	docker-compose -f docker-compose.mage.yml down

restart: ## Restart all stacks
	$(MAKE) down
	$(MAKE) up

# Production
prod-up: ## Start production stack
	docker-compose -f docker-compose.dw.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml up -d

prod-down: ## Stop production stack
	docker-compose -f docker-compose.dw.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml down

# Development
dev-up: ## Start development stack with debug logging
	docker-compose -f docker-compose.dw.yml -f docker-compose.monitoring.yml -f docker-compose.override.yml up -d

# Logs
logs: ## Show all logs
	docker-compose -f docker-compose.dw.yml logs -f &
	docker-compose -f docker-compose.monitoring.yml logs -f

# Status
status: ## Show container status
	@echo "Data Warehouse Stack:"
	@docker-compose -f docker-compose.dw.yml ps
	@echo ""
	@echo "Monitoring Stack:"
	@docker-compose -f docker-compose.monitoring.yml ps

# Cleanup
clean: ## Remove all containers, networks, and volumes
	docker-compose -f docker-compose.dw.yml down -v --remove-orphans
	docker-compose -f docker-compose.monitoring.yml down -v --remove-orphans
	docker system prune -f

# Individual service management
airflow-logs: ## Show Airflow logs
	docker-compose -f docker-compose.dw.yml logs -f airflow

clickhouse-logs: ## Show ClickHouse logs
	docker-compose -f docker-compose.dw.yml logs -f clickhouse

superset-logs: ## Show Superset logs
	docker-compose -f docker-compose.dw.yml logs -f superset

prometheus-logs: ## Show Prometheus logs
	docker-compose -f docker-compose.monitoring.yml logs -f prometheus

grafana-logs: ## Show Grafana logs
	docker-compose -f docker-compose.monitoring.yml logs -f grafana

# Database operations
init-db: ## Initialize databases
	@echo "Initializing ClickHouse database..."
	docker-compose -f docker-compose.dw.yml exec clickhouse clickhouse-client --query "CREATE DATABASE IF NOT EXISTS analytics"
	@echo "Database initialization complete"

# Backup operations
backup: ## Backup data volumes
	@echo "Creating backup..."
	@mkdir -p ./backups/$(shell date +%Y%m%d_%H%M%S)
	@docker run --rm -v dw_clickhouse_data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/$(shell date +%Y%m%d_%H%M%S)/clickhouse_backup.tar.gz -C /data .
	@echo "Backup created in ./backups/"

# Health checks
health: ## Check health of all services
	@echo "Checking service health..."
	@echo "Using ports from .env file (if available)..."
	@curl -f http://localhost:${AIRFLOW_PORT:-8080}/health || echo "Airflow: DOWN"
	@curl -f http://localhost:${SUPERSET_PORT:-8088}/health || echo "Superset: DOWN"
	@curl -f http://localhost:${GRAFANA_PORT:-3000}/api/health || echo "Grafana: DOWN"
	@curl -f http://localhost:${PROMETHEUS_PORT:-9090}/-/healthy || echo "Prometheus: DOWN"
	@curl -f http://localhost:${DATAHUB_PORT:-9002}/health || echo "DataHub: DOWN"

# Show configured ports
ports: ## Show configured ports for all services
	@echo "Service Ports Configuration:"
	@echo "=========================="
	@echo "Airflow:     http://localhost:${AIRFLOW_PORT:-8080}"
	@echo "Superset:    http://localhost:${SUPERSET_PORT:-8088}"
	@echo "Grafana:     http://localhost:${GRAFANA_PORT:-3000}"
	@echo "Prometheus:  http://localhost:${PROMETHEUS_PORT:-9090}"
	@echo "DataHub:     http://localhost:${DATAHUB_PORT:-9002}"
	@echo "MinIO API:   http://localhost:${MINIO_API_PORT:-9000}"
	@echo "MinIO Console: http://localhost:${MINIO_CONSOLE_PORT:-9001}"
	@echo "ClickHouse:  http://localhost:${CLICKHOUSE_HTTP_PORT:-8123}"
	@echo "Redis:       localhost:${REDIS_PORT:-6379}"
	@echo "Loki:        http://localhost:${LOKI_PORT:-3100}"
