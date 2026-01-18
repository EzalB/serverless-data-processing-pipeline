import json
import os
import time
import uuid
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SERVICE_NAME = "aws-python-orchestrator"
ENV = os.getenv("ENV", "prod")


def handler(event, context):
    """
    Triggered by SQS messages originating from SNS.
    """

    logger.info("Received event: %s", json.dumps(event))

    for record in event.get("Records", []):
        body = record.get("body")

        # SNS message is wrapped inside SQS
        message = json.loads(body)
        payload = json.loads(message.get("Message", "{}"))

        response = {
            "request_id": str(uuid.uuid4()),
            "filename": payload.get("filename"),
            "schema_version": payload.get("schema_version"),
            "source": payload.get("source"),
            "status": "processed",
            "service": SERVICE_NAME,
            "env": ENV,
            "timestamp": int(time.time())
        }

        logger.info("Orchestration result: %s", json.dumps(response))

    return {
        "statusCode": 200,
        "body": "Orchestration complete"
    }
