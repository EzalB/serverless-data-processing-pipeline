# AWS Python Orchestrator

This service acts as the execution layer of the AWS serverless pipeline.

## Trigger
- SQS messages originating from SNS events

## Responsibilities
- Event orchestration
- Metadata enrichment
- Downstream routing (future)

## Runtime
- AWS Lambda (container-based)
- Python 3.11
