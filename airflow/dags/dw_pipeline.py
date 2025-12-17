from datetime import datetime, timedelta
import os
import logging

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.email import EmailOperator
from airflow.sensors.filesystem import FileSensor

from minio import Minio
import clickhouse_connect
import great_expectations as ge


RAW_BUCKET = os.environ.get("MINIO_BUCKET_RAW", "datalake-raw")
CH_HOST = "clickhouse"
CH_PORT = 8123
CH_USER = os.environ.get("CH_USER", "admin")
CH_PASSWORD = os.environ.get("CH_PASSWORD", "admin123")
CH_DB = os.environ.get("CH_DB", "analytics")


DEFAULT_ARGS = {
    "owner": "data-eng",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "email_on_failure": True,
    "email_on_retry": False,
    "email": ["admin@company.com"],
}


with DAG(
    dag_id="dw_orders_pipeline",
    default_args=DEFAULT_ARGS,
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,
    catchup=False,
    tags=["dw", "clickhouse", "dbt"],
) as dag:

    def upload_to_minio():
        logging.info("Starting upload to MinIO")
        client = Minio(
            "minio:9000",
            access_key=os.environ.get("MINIO_ROOT_USER", "minio"),
            secret_key=os.environ.get("MINIO_ROOT_PASSWORD", "minio12345"),
            secure=False,
        )
        src = "/opt/airflow/data/orders.csv"
        obj = "orders/ingest_date={{ ds }}/orders.csv"
        client.fput_object(RAW_BUCKET, obj, src)
        logging.info(f"Successfully uploaded {obj} to MinIO")

    def load_raw_to_clickhouse():
        logging.info("Starting data load to ClickHouse")
        client = clickhouse_connect.get_client(
            host=CH_HOST,
            port=CH_PORT,
            username=CH_USER,
            password=CH_PASSWORD,
            database=CH_DB,
        )
        client.command("CREATE DATABASE IF NOT EXISTS {}".format(CH_DB))
        client.command(
            """
                CREATE TABLE IF NOT EXISTS raw_orders (
                order_id UInt32,
                order_ts DateTime,
                customer_id UInt32,
                amount Decimal(10,2),
                status LowCardinality(String)
                ) ENGINE = MergeTree
                ORDER BY order_id
            """
        )

        # Load from the same CSV we uploaded (demo). In real life you'd load from lake/object storage
        with open("/opt/airflow/data/orders.csv", "r") as f:
            client.insert_csv(
                "raw_orders",
                f,
                column_names=["order_id", "order_ts", "customer_id", "amount", "status"],
                settings={"input_format_allow_errors_num": 1},
            )
        logging.info("Successfully loaded data to ClickHouse")

    def dq_check():
        logging.info("Starting data quality checks")
        client = clickhouse_connect.get_client(
            host=CH_HOST,
            port=CH_PORT,
            username=CH_USER,
            password=CH_PASSWORD,
            database=CH_DB,
        )
        
        # Basic checks: rowcount > 0, no nulls in primary fields
        rows = client.query("SELECT count(*) FROM raw_orders").result_rows[0][0]
        logging.info(f"Total rows in raw_orders: {rows}")
        assert rows > 0, "raw_orders is empty!"
        
        # Check for invalid order_ids
        nulls = client.query(
            "SELECT countIf(order_id = 0) FROM raw_orders"
        ).result_rows[0][0]
        assert nulls == 0, "Invalid order_id values detected"
        
        # Check for negative amounts
        negative_amounts = client.query(
            "SELECT countIf(amount < 0) FROM raw_orders"
        ).result_rows[0][0]
        assert negative_amounts == 0, "Negative amounts detected"
        
        # Check for future dates
        future_dates = client.query(
            "SELECT countIf(order_ts > now()) FROM raw_orders"
        ).result_rows[0][0]
        logging.warning(f"Future dates found: {future_dates}")
        
        logging.info("Data quality checks passed successfully")

    # File sensor to wait for data file
    file_sensor = FileSensor(
        task_id="wait_for_data_file",
        filepath="/opt/airflow/data/orders.csv",
        poke_interval=30,
        timeout=300,
    )

    # Data ingestion tasks
    upload_task = PythonOperator(
        task_id="upload_to_minio", 
        python_callable=upload_to_minio
    )
    
    load_task = PythonOperator(
        task_id="load_raw_to_clickhouse", 
        python_callable=load_raw_to_clickhouse
    )

    # Data transformation with dbt
    dbt_deps = BashOperator(
        task_id="dbt_deps",
        bash_command="cd /opt/airflow/dags/dbt && dbt deps",
    )
    
    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command="cd /opt/airflow/dags/dbt && dbt run --profiles-dir . --target dev",
    )
    
    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command="cd /opt/airflow/dags/dbt && dbt test --profiles-dir . --target dev",
    )

    # Data quality checks
    dq_check_task = PythonOperator(
        task_id="data_quality_checks", 
        python_callable=dq_check
    )

    # Success notification
    success_notification = EmailOperator(
        task_id="success_notification",
        to=["admin@company.com"],
        subject="Data Pipeline Success - {{ ds }}",
        html_content="<h3>Data Pipeline Completed Successfully</h3><p>Date: {{ ds }}</p>",
        trigger_rule="all_success"
    )

    # Define task dependencies
    file_sensor >> upload_task >> load_task >> dbt_deps >> dbt_run >> dbt_test >> dq_check_task >> success_notification
