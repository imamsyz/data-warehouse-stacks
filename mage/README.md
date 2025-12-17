# Mage AI Orchestration Setup

This directory contains the Mage AI orchestration configuration and pipelines for the data warehouse project.

## Overview

Mage AI is a modern data orchestration platform that provides:
- **Visual Pipeline Builder**: Drag-and-drop interface for creating data pipelines
- **Code-First Approach**: Write pipelines in Python with full IDE support
- **Real-time Collaboration**: Multiple users can work on pipelines simultaneously
- **Advanced Scheduling**: Cron-based and event-driven scheduling
- **Data Quality**: Built-in data validation and testing
- **LLM Integration**: AI-powered pipeline generation and optimization

## Services

The standalone Mage AI stack includes:

- **mage**: Main Mage AI server with web UI
- **mage-db**: PostgreSQL database for Mage AI metadata
- **mage-redis**: Redis cache for performance
- **mage-scheduler**: Advanced scheduling service
- **mage-worker**: Distributed processing worker
- **mage-connector**: ClickHouse integration service
- **clickhouse**: ClickHouse data warehouse (standalone)
- **minio**: MinIO object storage (standalone)
- **mc**: MinIO client for bucket setup

## Quick Start

1. **Start Mage AI services:**
   ```bash
   docker-compose -f docker-compose.mage.yml up -d
   ```

2. **Access Mage AI UI:**
   - Mage AI UI: http://localhost:6789 (no auth required)
   - ClickHouse: http://localhost:8123
   - MinIO Console: http://localhost:9001 (minioadmin/minioadmin)

3. **View logs:**
   ```bash
   docker-compose -f docker-compose.mage.yml logs -f mage
   ```

## Configuration

### Environment Variables

Add these variables to your `.env` file:

```bash
# Mage AI Configuration
MAGE_DB_USER=mage
MAGE_DB_PASSWORD=mage
MAGE_DB_NAME=mage
MAGE_DB_PORT=5433
MAGE_REDIS_PORT=6380
MAGE_PORT=6789
MAGE_SECRET_KEY=your-secret-key-change-this

# Integration with existing services
CH_DB=default
CH_USER=default
CH_PASSWORD=
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
MINIO_BUCKET_RAW=datalake-raw
MINIO_BUCKET_WAREHOUSE=datalake-warehouse
```

### Configuration File

The `mage_config.yaml` file contains detailed configuration options for:
- Server settings
- Database connections
- Data warehouse integrations
- Object storage configuration
- Logging preferences
- Feature flags

## Pipeline Development

### Sample Pipeline

The `pipelines/sample_data_pipeline.py` demonstrates:
- Data loading from CSV files
- Data transformation and cleaning
- Export to ClickHouse
- Export to MinIO object storage
- Logging with timezone support (Asia/Jakarta)

### Creating New Pipelines

1. **Using the Web UI:**
   - Navigate to http://localhost:6789
   - Click "New Pipeline"
   - Use the visual builder or code editor

2. **Using Code:**
   - Create a new Python file in `pipelines/`
   - Use Mage AI decorators: `@data_loader`, `@transformer`, `@data_exporter`
   - Follow the sample pipeline structure

### Pipeline Decorators

- `@data_loader`: Load data from various sources
- `@transformer`: Transform and clean data
- `@data_exporter`: Export data to destinations
- `@test`: Add data quality tests
- `@retry`: Configure retry logic

## Data Sources & Destinations

### Supported Sources
- CSV/JSON files
- ClickHouse
- PostgreSQL
- MinIO/S3
- APIs (REST, GraphQL)
- Databases (MySQL, PostgreSQL, etc.)

### Supported Destinations
- ClickHouse
- MinIO/S3
- PostgreSQL
- APIs
- Files (CSV, Parquet, JSON)

## Integration with Existing Stack

Mage AI integrates seamlessly with:
- **ClickHouse**: Direct connection for data warehouse operations
- **MinIO**: Object storage for raw and processed data
- **Airflow**: Can be used alongside or as replacement
- **Superset**: Data visualization from Mage AI processed data

## Monitoring & Logging

- **Logs**: Available via `docker-compose logs mage`
- **Metrics**: Built-in performance monitoring
- **Health Checks**: Automatic service health monitoring
- **Timezone**: All timestamps in Asia/Jakarta timezone

## Advanced Features

### Scheduling
- Cron-based scheduling
- Event-driven triggers
- Conditional execution
- Pipeline dependencies

### Data Quality
- Great Expectations integration
- Custom validation rules
- Data profiling
- Anomaly detection

### Collaboration
- Git integration
- Version control
- Code review workflows
- Team collaboration tools

## Troubleshooting

### Common Issues

1. **Database Connection Error:**
   ```bash
   docker-compose -f docker-compose.mage.yml logs mage-db
   ```

2. **ClickHouse Connection Error:**
   - Ensure ClickHouse is running: `docker-compose -f docker-compose.dw.yml up -d clickhouse`
   - Check connection settings in `mage_config.yaml`

3. **MinIO Connection Error:**
   - Ensure MinIO is running: `docker-compose -f docker-compose.dw.yml up -d minio`
   - Verify bucket permissions

### Useful Commands

```bash
# Restart Mage AI services
docker-compose -f docker-compose.mage.yml restart

# View all logs
docker-compose -f docker-compose.mage.yml logs

# Access Mage AI container
docker exec -it mage bash

# Check service status
docker-compose -f docker-compose.mage.yml ps
```

## Production Considerations

1. **Security:**
   - Enable authentication in `mage_config.yaml`
   - Use strong secret keys
   - Configure CORS properly

2. **Performance:**
   - Adjust worker count based on resources
   - Configure Redis for optimal caching
   - Monitor memory usage

3. **Backup:**
   - Regular database backups
   - Pipeline code version control
   - Configuration backup

## Support

- **Documentation**: https://docs.mage.ai/
- **Community**: https://github.com/mage-ai/mage-ai
- **Issues**: Report issues in the project repository
