from google.cloud import bigquery
from datetime import datetime, timedelta
from google.api_core.exceptions import Conflict

def create_sharded_table(request):
    project_id = "snowplow-test-447809"
    dataset_id = "snowplow_snowplow_db"
    table_base = "events"
    yesterday = (datetime.utcnow() - timedelta(days=1)).strftime("%Y%m%d")
    table_id = f"{project_id}.{dataset_id}.{table_base}_{yesterday}"

    client = bigquery.Client(project=project_id)

    schema = client.get_table(f"{project_id}.{dataset_id}.events").schema

    

    # Compose your CREATE TABLE AS SELECT SQL query with the date variable
    query = f"""
    CREATE OR REPLACE TABLE `{table_id}` AS
    SELECT * FROM `{project_id}.{dataset_id}.{table_base}`
    WHERE DATE(collector_tstamp) = DATE('{yesterday[:4]}-{yesterday[4:6]}-{yesterday[6:]}')
    """

    # Run the query
    query_job = client.query(query)
    query_job.result()  # Wait for the job to complete

    return f"Created or replaced table: {table_id} with data for {yesterday}"

