from airflow import DAG
from airflow.models import Connection
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.google.cloud.transfers.postgres_to_gcs import PostgresToGCSOperator
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.utils.dates import days_ago
from datetime import timedelta
from airflow.hooks.base import BaseHook
from airflow.operators.python import PythonOperator


# Connection IDs
POSTGRES_CONN_ID = 'alt_capstone_pg_conn'
GCP_CONN_ID = 'alt_cap_gcp_conn'

# DAG configuration
DAG_ID = 'postgres_to_gcs_to_bigquery'
SCHEDULE_INTERVAL = '@daily'
START_DATE = days_ago(1)

# GCS and BigQuery configuration
GCS_BUCKET = 'etl_basic'
PROJECT_ID = 'pygcs-425623'
DATASET_ID = 'capstone_etl'


default_args = {
    'owner': 'alt_capstone',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

def test_connections():
    # Test PostgreSQL connection
    try:
        postgres_hook = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID)
        postgres_conn = postgres_hook.get_conn()
        cursor = postgres_conn.cursor()
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        print(f"PostgreSQL Connection Test: {result}")
    except Exception as e:
        print(f"PostgreSQL Connection Error: {str(e)}")

    # Test Google Cloud connection
    try:
        gcp_conn = BaseHook.get_connection(GCP_CONN_ID)
        print(f"GCP Connection Test - Project ID: {gcp_conn.extra_dejson.get('project')}")
    except Exception as e:
        print(f"GCP Connection Error: {str(e)}")    


def get_postgres_tables():
    hook = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID)
    # Query to get all table names from a specific schema
    sql = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'alt_cap'"
    return [row[0] for row in hook.get_records(sql)]


with DAG(
    DAG_ID,
    default_args=default_args,
    description='Transfer data from PostgreSQL to GCS to BigQuery',
    schedule_interval=SCHEDULE_INTERVAL,
    start_date=START_DATE,
    catchup=False,
    tags=['postgres', 'gcs', 'bigquery'],
) as dag:
    
    test_connections_task = PythonOperator(
    task_id='test_connections',
    python_callable=test_connections,
    dag=dag
    )

    tables = get_postgres_tables()

    for table in tables:
        postgres_to_gcs = PostgresToGCSOperator(
            task_id=f'postgres_to_gcs_{table}',
            postgres_conn_id=POSTGRES_CONN_ID,
            google_cloud_storage_conn_id=GCP_CONN_ID,
            sql=f'SELECT * FROM {table}',
            bucket=GCS_BUCKET,
            filename=f'data/{table}/{{{{ ds }}}}/{table}.csv',
            export_format='csv',
            use_server_side_cursor=True,
        )

    gcs_to_bigquery = GCSToBigQueryOperator(
            task_id=f'gcs_to_bigquery_{table}',
            bucket=GCS_BUCKET,
            source_objects=[f'data/{table}/{{{{ ds }}}}/{table}.csv'],
            destination_project_dataset_table=f'{PROJECT_ID}.{DATASET_ID}.{table}',
            write_disposition='WRITE_TRUNCATE',
            source_format='CSV',
            autodetect=True,
            bigquery_conn_id=GCP_CONN_ID,
            google_cloud_storage_conn_id=GCP_CONN_ID,
        )


    
    test_connections_task >> postgres_to_gcs >> gcs_to_bigquery
    