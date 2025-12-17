# Data Warehouse Stack

> **Disclaimer:**  
This project is a proof of concept (POC), is not thoroughly tested, and is **not recommended for production environments**.


A modern, open-source data warehouse stack built with Airflow, ClickHouse, dbt, and more.

## Architecture

- **Orchestration**: Apache Airflow + Mage AI
- **Data Warehouse**: ClickHouse
- **Object Storage**: MinIO (S3-compatible)
- **Transformation**: dbt + Mage AI
- **Visualization**: Apache Superset
- **Monitoring**: Prometheus + Grafana
- **Data Lineage**: DataHub
- **Caching**: Redis

## Quick Start

1. **Create environment file**:
```bash
cp .env.example .env
# Edit .env with your configuration
```

2. **Start the stack**:

**Option A: Start everything (recommended)**
```bash
make up
# or
docker-compose -f docker-compose.dw.yml up -d
docker-compose -f docker-compose.monitoring.yml up -d
docker-compose -f docker-compose.mage.yml up -d
```

**Option B: Start only data warehouse**
```bash
make dw-up
# or
docker-compose -f docker-compose.dw.yml up -d
```

**Option C: Start only monitoring**
```bash
make monitoring-up
# or
docker-compose -f docker-compose.monitoring.yml up -d
```

**Option D: Start only Mage AI (standalone)**
```bash
make mage-up
# or
docker-compose -f docker-compose.mage.yml up -d
# or use the standalone script
cd mage && ./start-standalone.sh
```

3. **Access services**:
- Airflow: http://localhost:8080 (admin/admin)
- Superset: http://localhost:8088 (admin/admin)
- Grafana: http://localhost:3000 (admin/admin)
- Mage AI: http://localhost:6789 (no auth required)
- Prometheus: http://localhost:9090
- DataHub: http://localhost:9002
- MinIO Console: http://localhost:9001 (minio/minio12345)

## Environment Variables

Create a `.env` file with the following variables:

```bash
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
SUPERSET_SECRET=your-secret-key-here
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
```

### Port Configuration

All services use configurable ports through environment variables. Default ports are:

| Service | Default Port | Environment Variable |
|---------|-------------|---------------------|
| Airflow | 8080 | `AIRFLOW_PORT` |
| Superset | 8088 | `SUPERSET_PORT` |
| Grafana | 3000 | `GRAFANA_PORT` |
| Prometheus | 9090 | `PROMETHEUS_PORT` |
| DataHub | 9002 | `DATAHUB_PORT` |
| MinIO API | 9000 | `MINIO_API_PORT` |
| MinIO Console | 9001 | `MINIO_CONSOLE_PORT` |
| ClickHouse HTTP | 8123 | `CLICKHOUSE_HTTP_PORT` |
| ClickHouse Native | 9000 | `CLICKHOUSE_NATIVE_PORT` |
| Redis | 6379 | `REDIS_PORT` |
| Loki | 3100 | `LOKI_PORT` |

**Note**: If you change ports, make sure they don't conflict with other services on your system.

## Features

### Data Quality
- dbt-expectations for data validation
- Great Expectations integration
- Automated data quality checks in Airflow

### Monitoring
- Prometheus for metrics collection
- Grafana for visualization and alerting
- Custom dashboards for data pipeline monitoring

### Data Lineage
- DataHub for data lineage tracking
- dbt documentation generation
- Automated lineage discovery

### Enhanced dbt Models
- Staging layer with data quality flags
- Marts layer with business logic
- Comprehensive testing framework
- Customer segmentation and analytics

## Data Pipeline

The main pipeline (`dw_orders_pipeline`) includes:

1. **File Sensor**: Waits for data file availability
2. **Data Ingestion**: Uploads to MinIO object storage
3. **Data Loading**: Loads raw data to ClickHouse
4. **Data Transformation**: Runs dbt models and tests
5. **Data Quality**: Validates data quality
6. **Notifications**: Sends success/failure alerts

## dbt Models

### Staging Layer (`stg_orders`)
- Data cleaning and validation
- Data quality flags
- Type casting and formatting

### Marts Layer
- **`fct_orders`**: Fact table with business metrics
- **`dim_customers`**: Customer dimension with segmentation

## Monitoring Dashboards

Grafana dashboards are automatically provisioned for:
- Data pipeline health
- ClickHouse performance
- Airflow task monitoring
- Data quality metrics

## Docker Compose Structure

The project uses a modular docker-compose approach:

### Files Overview
- **`docker-compose.dw.yml`**: Data warehouse services (MinIO, ClickHouse, Airflow, Superset, Redis)
- **`docker-compose.monitoring.yml`**: Monitoring services (Prometheus, Grafana, DataHub, Loki)
- **`docker-compose.override.yml`**: Development overrides (debug logging, additional volumes)
- **`docker-compose.prod.yml`**: Production overrides (resource limits, optimized settings)
- **`Makefile`**: Convenient commands for stack management

### Available Commands

**Using Makefile (recommended):**
```bash
make help              # Show all available commands
make up                # Start both stacks
make dw-up             # Start only data warehouse
make monitoring-up     # Start only monitoring
make mage-up           # Start only Mage AI
make down              # Stop all stacks
make logs              # Show all logs
make status            # Show container status
make health            # Check service health
make clean             # Clean up everything
```

**Using Docker Compose directly:**
```bash
# Data warehouse only
docker-compose -f docker-compose.dw.yml up -d

# Monitoring only
docker-compose -f docker-compose.monitoring.yml up -d

# Mage AI only
docker-compose -f docker-compose.mage.yml up -d

# Development with debug logging
docker-compose -f docker-compose.dw.yml -f docker-compose.monitoring.yml -f docker-compose.override.yml up -d

# Production
docker-compose -f docker-compose.dw.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml up -d
```

## Development

### Adding New dbt Models
1. Create model in appropriate directory (`staging/` or `marts/`)
2. Add tests in `schema.yml`
3. Run `dbt run` and `dbt test`

### Adding New Airflow DAGs
1. Create Python file in `airflow/dags/`
2. Follow existing patterns for logging and error handling
3. Include data quality checks

### Data Quality Tests
Tests are defined in `schema.yml` and include:
- Uniqueness tests
- Not null tests
- Range validations
- Custom business logic tests

### Adding New Mage AI Pipelines
1. Create Python file in `mage/pipelines/`
2. Use Mage AI decorators: `@data_loader`, `@transformer`, `@data_exporter`
3. Follow the sample pipeline structure in `mage/pipelines/sample_data_pipeline.py`
4. Access Mage AI UI at http://localhost:6789 for visual pipeline building

## Troubleshooting

### Common Issues
1. **Permission errors**: Check `AIRFLOW_UID` and `AIRFLOW_GID` in `.env`
2. **Connection issues**: Verify all services are running with `docker-compose ps`
3. **dbt errors**: Check ClickHouse connection and model syntax

### Logs
- Airflow logs: Available in Airflow UI
- Service logs: `docker-compose logs <service_name>`
- dbt logs: Check Airflow task logs

## Contributing

1. Follow existing code patterns
2. Add tests for new functionality
3. Update documentation
4. Use logging instead of print statements
5. Follow data quality best practices
