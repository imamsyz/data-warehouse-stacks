from mage_ai.io.file import FileIO
import pandas as pd
import structlog
from datetime import datetime, timezone
import pytz
import logging as logger



# Configure logging with timezone preference
logger = structlog.get_logger()

# Set timezone to Asia/Jakarta as per user preference
JAKARTA_TZ = pytz.timezone('Asia/Jakarta')

if 'data_loader' not in globals():
    from mage_ai.data_preparation.decorators import data_loader
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test


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


@test
def test_output(output, *args) -> None:
    """
    Template code for testing the output of the block.
    """
    assert output is not None, 'The output is undefined'
