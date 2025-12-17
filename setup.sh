#!/bin/bash

# Data Warehouse Stack Setup Script
# This script helps set up the environment and start the stack

set -e

echo "🚀 Data Warehouse Stack Setup"
echo "=============================="

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cat > .env << EOF
# MinIO Configuration
MINIO_ROOT_USER=minio
MINIO_ROOT_PASSWORD=minio12345
MINIO_BUCKET_RAW=datalake-raw
MINIO_BUCKET_WAREHOUSE=datalake-warehouse
MINIO_API_PORT=9000
MINIO_CONSOLE_PORT=9001

# ClickHouse Configuration
CH_DB=analytics
CH_USER=admin
CH_PASSWORD=admin123
CLICKHOUSE_HTTP_PORT=8123
CLICKHOUSE_NATIVE_PORT=9000

# Airflow Configuration
AIRFLOW_UID=50000
AIRFLOW_GID=0
AIRFLOW_USER=admin
AIRFLOW_PWD=admin
AIRFLOW_EMAIL=admin@company.com
AIRFLOW_PORT=8080

# Superset Configuration
SUPERSET_SECRET=your-secret-key-here-$(date +%s)
SUPERSET_ADMIN=admin
SUPERSET_EMAIL=admin@company.com
SUPERSET_PWD=admin
SUPERSET_PORT=8088

# Redis Configuration
REDIS_PORT=6379

# Monitoring Configuration
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
GRAFANA_PASSWORD=admin
DATAHUB_PORT=9002
LOKI_PORT=3100

# DataHub Configuration
DATAHUB_ANALYTICS_ENABLED=false
EOF
    echo "✅ .env file created"
else
    echo "✅ .env file already exists"
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p minio clickhouse airflow/db airflow/logs superset monitoring/prometheus monitoring/grafana/provisioning/datasources monitoring/grafana/provisioning/dashboards monitoring/grafana/dashboards

# Set permissions for Airflow
echo "🔐 Setting up permissions..."
if [ -n "$AIRFLOW_UID" ] && [ -n "$AIRFLOW_GID" ]; then
    sudo chown -R ${AIRFLOW_UID}:${AIRFLOW_GID} ./airflow
    echo "✅ Airflow permissions set"
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Make is available
if ! command -v make &> /dev/null; then
    echo "⚠️  Make is not available. You can still use docker-compose commands directly."
    USE_MAKE=false
else
    USE_MAKE=true
fi

# Ask user what to start
echo ""
echo "What would you like to start?"
echo "1) Data Warehouse only"
echo "2) Monitoring only"
echo "3) Both stacks (recommended)"
echo "4) Development mode (with debug logging)"
echo "5) Production mode"
echo "6) Skip starting services"

read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        echo "🏗️  Starting Data Warehouse stack..."
        if [ "$USE_MAKE" = true ]; then
            make dw-up
        else
            docker-compose -f docker-compose.dw.yml up -d
        fi
        ;;
    2)
        echo "📊 Starting Monitoring stack..."
        if [ "$USE_MAKE" = true ]; then
            make monitoring-up
        else
            docker-compose -f docker-compose.monitoring.yml up -d
        fi
        ;;
    3)
        echo "🚀 Starting both stacks..."
        if [ "$USE_MAKE" = true ]; then
            make up
        else
            docker-compose -f docker-compose.dw.yml up -d
            docker-compose -f docker-compose.monitoring.yml up -d
        fi
        ;;
    4)
        echo "🔧 Starting in development mode..."
        if [ "$USE_MAKE" = true ]; then
            make dev-up
        else
            docker-compose -f docker-compose.dw.yml -f docker-compose.monitoring.yml -f docker-compose.override.yml up -d
        fi
        ;;
    5)
        echo "🏭 Starting in production mode..."
        if [ "$USE_MAKE" = true ]; then
            make prod-up
        else
            docker-compose -f docker-compose.dw.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml up -d
        fi
        ;;
    6)
        echo "⏭️  Skipping service startup"
        ;;
    *)
        echo "❌ Invalid choice. Skipping service startup."
        ;;
esac

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Wait for services to start (may take a few minutes)"
echo "2. Check service status with: make status"
echo "3. View logs with: make logs"
echo "4. Access services:"
echo "   - Airflow: http://localhost:${AIRFLOW_PORT:-8080} (admin/admin)"
echo "   - Superset: http://localhost:${SUPERSET_PORT:-8088} (admin/admin)"
echo "   - Grafana: http://localhost:${GRAFANA_PORT:-3000} (admin/admin)"
echo "   - Prometheus: http://localhost:${PROMETHEUS_PORT:-9090}"
echo "   - DataHub: http://localhost:${DATAHUB_PORT:-9002}"
echo "   - MinIO API: http://localhost:${MINIO_API_PORT:-9000}"
echo "   - MinIO Console: http://localhost:${MINIO_CONSOLE_PORT:-9001} (minio/minio12345)"
echo "   - ClickHouse: http://localhost:${CLICKHOUSE_HTTP_PORT:-8123}"
echo "   - Redis: localhost:${REDIS_PORT:-6379}"
echo ""
echo "📚 For more commands, run: make help"
