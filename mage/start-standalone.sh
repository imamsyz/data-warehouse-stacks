#!/bin/bash

# Mage AI Standalone Startup Script
# This script starts the complete Mage AI stack with all dependencies

set -e

echo "🚀 Starting Mage AI Standalone Stack..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file with default values..."
    cat > .env << EOF
# Mage AI Configuration
MAGE_DB_USER=mage
MAGE_DB_PASSWORD=mage
MAGE_DB_NAME=mage
MAGE_DB_PORT=5433
MAGE_REDIS_PORT=6380
MAGE_PORT=6789
MAGE_SECRET_KEY=your-secret-key-change-this-in-production

# ClickHouse Configuration
CH_DB=default
CH_USER=default
CH_PASSWORD=
CLICKHOUSE_HTTP_PORT=8123
CLICKHOUSE_NATIVE_PORT=9000

# MinIO Configuration
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
MINIO_API_PORT=9000
MINIO_CONSOLE_PORT=9001
MINIO_BUCKET_RAW=datalake-raw
MINIO_BUCKET_WAREHOUSE=datalake-warehouse

# Timezone Configuration
TZ=Asia/Jakarta
EOF
    echo "✅ Created .env file with default values"
fi

# Build custom Mage AI image
echo "🔨 Building custom Mage AI image..."
docker-compose -f docker-compose.mage.yml build

# Start the services
echo "🐳 Starting Docker containers..."
docker-compose -f docker-compose.mage.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service health
echo "🔍 Checking service health..."

# Check Mage AI
if curl -s http://localhost:6789 > /dev/null; then
    echo "✅ Mage AI is running at http://localhost:6789"
else
    echo "⚠️  Mage AI is starting up, please wait a moment..."
fi

# Check ClickHouse
if curl -s http://localhost:8123/ping > /dev/null; then
    echo "✅ ClickHouse is running at http://localhost:8123"
else
    echo "⚠️  ClickHouse is starting up, please wait a moment..."
fi

# Check MinIO
if curl -s http://localhost:9000/minio/health/live > /dev/null; then
    echo "✅ MinIO is running at http://localhost:9001"
else
    echo "⚠️  MinIO is starting up, please wait a moment..."
fi

echo ""
echo "🎉 Mage AI Standalone Stack is starting up!"
echo ""
echo "📊 Access your services:"
echo "   • Mage AI UI:     http://localhost:6789"
echo "   • ClickHouse:     http://localhost:8123"
echo "   • MinIO Console:  http://localhost:9001 (minioadmin/minioadmin)"
echo ""
echo "📝 View logs:"
echo "   docker-compose -f docker-compose.mage.yml logs -f"
echo ""
echo "🛑 Stop services:"
echo "   docker-compose -f docker-compose.mage.yml down"
echo ""
