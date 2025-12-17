"""
Sample Mage AI Pipeline for Data Warehouse
This pipeline demonstrates data ingestion, transformation, and loading.
"""

import pandas as pd
import structlog
from datetime import datetime, timezone
import pytz

# Configure logging with timezone preference
logger = structlog.get_logger()

# Set timezone to Asia/Jakarta as per user preference
JAKARTA_TZ = pytz.timezone('Asia/Jakarta')

@data_loader
def load_data_from_csv(**kwargs) -> pd.DataFrame:
    """
    Load data from CSV file in the data directory.
    """
    logger.info("Loading data from CSV file")
    
    # Load the order data
    df = pd.read_csv('/home/mage/data/order.csv')
    
    # Add timestamp with Jakarta timezone
    current_time = datetime.now(JAKARTA_TZ)
    df['loaded_at'] = current_time.isoformat()
    
    logger.info(f"Loaded {len(df)} rows from CSV")
    return df

@transformer
def transform_data(df: pd.DataFrame, **kwargs) -> pd.DataFrame:
    """
    Transform the data by cleaning and enriching it.
    """
    logger.info("Starting data transformation")
    
    # Clean the data
    df_clean = df.copy()
    
    # Remove duplicates
    df_clean = df_clean.drop_duplicates()
    
    # Handle missing values
    df_clean = df_clean.fillna({
        'customer_name': 'Unknown',
        'product_name': 'Unknown Product'
    })
    
    # Add calculated fields
    if 'quantity' in df_clean.columns and 'price' in df_clean.columns:
        df_clean['total_amount'] = df_clean['quantity'] * df_clean['price']
    
    # Add transformation timestamp
    current_time = datetime.now(JAKARTA_TZ)
    df_clean['transformed_at'] = current_time.isoformat()
    
    logger.info(f"Transformed {len(df_clean)} rows")
    return df_clean

@data_exporter
def export_to_clickhouse(df: pd.DataFrame, **kwargs) -> None:
    """
    Export transformed data to ClickHouse.
    """
    logger.info("Exporting data to ClickHouse")
    
    try:
        # Import ClickHouse connector
        from clickhouse_connect import get_client
        
        # Connect to ClickHouse
        client = get_client(
            host='clickhouse',
            port=8123,
            username='default',
            password='',
            database='default'
        )
        
        # Create table if not exists
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS orders (
            id UInt64,
            customer_name String,
            product_name String,
            quantity UInt32,
            price Float64,
            total_amount Float64,
            order_date Date,
            loaded_at DateTime,
            transformed_at DateTime
        ) ENGINE = MergeTree()
        ORDER BY (id, order_date)
        """
        
        client.command(create_table_sql)
        
        # Insert data
        client.insert_df('orders', df)
        
        logger.info(f"Successfully exported {len(df)} rows to ClickHouse")
        
    except Exception as e:
        logger.error(f"Failed to export to ClickHouse: {str(e)}")
        raise

@data_exporter
def export_to_minio(df: pd.DataFrame, **kwargs) -> None:
    """
    Export data to MinIO object storage as Parquet.
    """
    logger.info("Exporting data to MinIO")
    
    try:
        import boto3
        from io import BytesIO
        
        # Configure MinIO client
        s3_client = boto3.client(
            's3',
            endpoint_url='http://minio:9000',
            aws_access_key_id='minioadmin',
            aws_secret_access_key='minioadmin',
            region_name='us-east-1'
        )
        
        # Convert DataFrame to Parquet
        parquet_buffer = BytesIO()
        df.to_parquet(parquet_buffer, index=False)
        parquet_buffer.seek(0)
        
        # Upload to MinIO
        bucket_name = 'datalake-warehouse'
        object_key = f'processed/orders_{datetime.now(JAKARTA_TZ).strftime("%Y%m%d_%H%M%S")}.parquet'
        
        s3_client.put_object(
            Bucket=bucket_name,
            Key=object_key,
            Body=parquet_buffer.getvalue()
        )
        
        logger.info(f"Successfully uploaded data to MinIO: {object_key}")
        
    except Exception as e:
        logger.error(f"Failed to export to MinIO: {str(e)}")
        raise
