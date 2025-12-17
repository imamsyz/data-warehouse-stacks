import pandas as pd
import structlog
from datetime import datetime, timezone
import pytz
import logging as logger

if 'transformer' not in globals():
    from mage_ai.data_preparation.decorators import transformer
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test


# Configure logging with timezone preference
logger = structlog.get_logger()

# Set timezone to Asia/Jakarta as per user preference
JAKARTA_TZ = pytz.timezone('Asia/Jakarta')

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



@test
def test_output(output, *args) -> None:
    """
    Template code for testing the output of the block.
    """
    assert output is not None, 'The output is undefined'
