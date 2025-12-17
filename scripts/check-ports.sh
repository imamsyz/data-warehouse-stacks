#!/bin/bash

# Port Configuration Checker
# This script checks if the configured ports are available

set -e

echo "🔍 Checking port configuration..."
echo "================================"

# Load environment variables
if [ -f .env ]; then
    source .env
    echo "✅ Loaded .env file"
else
    echo "⚠️  No .env file found, using default ports"
fi

# Function to check if port is available
check_port() {
    local port=$1
    local service=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "❌ Port $port ($service) is already in use"
        return 1
    else
        echo "✅ Port $port ($service) is available"
        return 0
    fi
}

# Check all configured ports
echo ""
echo "Checking configured ports:"
echo "-------------------------"

check_port ${AIRFLOW_PORT:-8080} "Airflow"
check_port ${SUPERSET_PORT:-8088} "Superset"
check_port ${GRAFANA_PORT:-3000} "Grafana"
check_port ${PROMETHEUS_PORT:-9090} "Prometheus"
check_port ${DATAHUB_PORT:-9002} "DataHub"
check_port ${MINIO_API_PORT:-9000} "MinIO API"
check_port ${MINIO_CONSOLE_PORT:-9001} "MinIO Console"
check_port ${CLICKHOUSE_HTTP_PORT:-8123} "ClickHouse HTTP"
check_port ${CLICKHOUSE_NATIVE_PORT:-9000} "ClickHouse Native"
check_port ${REDIS_PORT:-6379} "Redis"
check_port ${LOKI_PORT:-3100} "Loki"

echo ""
echo "🎯 Port check complete!"
echo ""
echo "If any ports are in use, you can:"
echo "1. Stop the conflicting services"
echo "2. Change the port in your .env file"
echo "3. Use 'make ports' to see current configuration"
