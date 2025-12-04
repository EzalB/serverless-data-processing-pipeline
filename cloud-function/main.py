import json
import os
from google.cloud import bigquery, pubsub_v1

# Environment variables
PROJECT_ID = os.getenv("GCP_PROJECT")
DATASET = "serverless_data_processing_dataset"
TABLE = "processed_data"
TOPIC = "data-processed-topic"

bq_client = bigquery.Client()
publisher = pubsub_v1.PublisherClient()

def validate_json(data, schema):
    for field in schema:
        if field["name"] not in data:
            raise ValueError(f"Missing field: {field['name']}")
    return True

def process_file(event, context):
    from google.cloud import storage
    storage_client = storage.Client()

    bucket = storage_client.bucket(event["bucket"])
    blob = bucket.blob(event["name"])
    content = blob.download_as_text()

    data = json.loads(content)

    # Load schema from file deployed with function
    with open("schema.json") as f:
        schema = json.load(f)

    # Validate all records
    if isinstance(data, list):
        for record in data:
            validate_json(record, schema)
    else:
        validate_json(data, schema)
        data = [data]

    # Convert to DataFrame and load into BigQuery
    df = pd.DataFrame(data)
    table_ref = bq_client.dataset(DATASET).table(TABLE)
    job = bq_client.load_table_from_dataframe(df, table_ref)
    job.result()

    # Publish message to Pub/Sub
    topic_path = publisher.topic_path(PROJECT_ID, TOPIC)
    publisher.publish(topic_path, b"Data processed", filename=event["name"])

    print(f"Processed file {event['name']} and loaded into BigQuery.")
