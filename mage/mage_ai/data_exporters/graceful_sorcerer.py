import pandas as pd
import structlog
from datetime import datetime, timezone
import pytz
if 'data_exporter' not in globals():
    from mage_ai.data_preparation.decorators import data_exporter
# Configure logging with timezone preference
logger = structlog.get_logger()

# Set timezone to Asia/Jakarta as per user preference
JAKARTA_TZ = pytz.timezone('Asia/Jakarta')



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
            username='dw_user',
            password='dwpassword',
            database='default'
        )
        
        # Create table if not exists
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS orders (
            order_id UInt64,
            customer_id UInt32,
            amount Float64,
            status String,
            price Float64,
            order_ts Date,
            loaded_at DateTime,
            transformed_at DateTime
        ) ENGINE = MergeTree()
        ORDER BY (order_id, order_ts)
        """
        
        client.command(create_table_sql)
        
                # Insert data
        # Format 'order_ts' column to date format (YYYY-MM-DD)
        if 'order_ts' in df.columns:
            df['order_ts'] = pd.to_datetime(df['order_ts']).dt.date

        # Format 'loaded_at' and 'transformed_at' columns to datetime format (with Asia/Jakarta timezone)
        for col in ['loaded_at', 'transformed_at']:
            if col in df.columns:
                df[col] = pd.to_datetime(df[col]) if pd.api.types.is_datetime64tz_dtype(df[col]) \
                    else pd.to_datetime(df[col])
        # Insert data
        client.insert_df('orders', df)
        
        logger.info(f"Successfully exported {len(df)} rows to ClickHouse")
        
    except Exception as e:
        logger.error(f"Failed to export to ClickHouse: {str(e)}")
        raise

