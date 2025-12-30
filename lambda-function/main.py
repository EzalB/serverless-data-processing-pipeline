import json
import os
import boto3
import uuid
import time
from urllib.parse import unquote_plus

# AWS Clients
s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")

# Environment Variables
TABLE_NAME = os.getenv("TABLE_NAME")
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")

if not TABLE_NAME or not SNS_TOPIC_ARN:
    raise RuntimeError("Missing required environment variables")

def validate_json(data, schema):
    for field in schema:
        if field["name"] not in data:
            raise ValueError(f"Missing field: {field['name']}")
    return True

def lambda_handler(event, context):
    try:
        print("Incoming event:", json.dumps(event))

        # Extract S3 details
        record = event["Records"][0]
        bucket = record["s3"]["bucket"]["name"]
        key = unquote_plus(record["s3"]["object"]["key"])

        # Download JSON file from S3
        response = s3.get_object(Bucket=bucket, Key=key)
        content = response["Body"].read().decode("utf-8")

        data = json.loads(content)

        # Load schema from Lambda package
        with open("schema.json") as f:
            schema = json.load(f)

        # Validate JSON
        if isinstance(data, list):
            records = data
        else:
            records = [data]

        for record in records:
            validate_json(record, schema)

        # Insert records into DynamoDB
        table = dynamodb.Table(TABLE_NAME)

        for record in records:
            item = {
                "record_id": str(uuid.uuid4()),
                "timestamp": int(time.time()),
                "source_file": key,
                **record
            }

            table.put_item(Item=item)

        # Publish SNS notification
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=json.dumps({
                "message": "Data processed",
                "file": key,
                "records": len(records)
            }),
            Subject="Data Processing Complete"
        )

        print(f"Processed {len(records)} records from {key}")

        return {
            "statusCode": 200,
            "body": "Success"
        }

    except Exception as e:
        print("ERROR:", str(e))
        raise
