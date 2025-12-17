
import pandas as pd
import structlog
from datetime import datetime, timezone
import pytz
import logging as logger

if 'transformer' not in globals():
    from mage_ai.data_preparation.decorators import data_exporter
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test


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



@test
def test_output(output, *args) -> None:
    """
    Template code for testing the output of the block.
    """
    assert output is not None, 'The output is undefined'
