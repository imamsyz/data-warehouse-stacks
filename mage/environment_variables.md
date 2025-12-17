# Environment Variables for Mage AI

Add these environment variables to your `.env` file or export them in your shell:

## Mage AI Specific Variables

```bash
# Mage AI Database
MAGE_DB_USER=mage
MAGE_DB_PASSWORD=mage
MAGE_DB_NAME=mage
MAGE_DB_PORT=5433

# Mage AI Redis
MAGE_REDIS_PORT=6380

# Mage AI Server
MAGE_PORT=6789
MAGE_SECRET_KEY=your-secret-key-change-this-in-production

# Timezone (Asia/Jakarta as per user preference)
TZ=Asia/Jakarta
```

## Standalone Service Variables

The standalone Mage AI stack includes its own ClickHouse and MinIO services:

```bash
# ClickHouse (standalone service)
CH_DB=default
CH_USER=default
CH_PASSWORD=
CLICKHOUSE_HTTP_PORT=8123
CLICKHOUSE_NATIVE_PORT=9000

# MinIO (standalone service)
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
MINIO_API_PORT=9000
MINIO_CONSOLE_PORT=9001
MINIO_BUCKET_RAW=datalake-raw
MINIO_BUCKET_WAREHOUSE=datalake-warehouse
```

## Quick Setup

1. Copy the variables above to your `.env` file
2. Update the secret key for production use
3. Start the services: `docker-compose -f docker-compose.mage.yml up -d`
