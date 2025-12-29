# ------------------------
# S3 Bucket for JSON uploads
# ------------------------
resource "aws_s3_bucket" "data_bucket" {
  bucket        = "${var.project_id}-data-bucket"
  force_destroy = true
}

# ------------------------
# S3 Bucket for Lambda code
# ------------------------
resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = "${var.project_id}-lambda-bucket"
  force_destroy = true
}

# ------------------------
# DynamoDB Table
# ------------------------
resource "aws_dynamodb_table" "processed_data" {
  name         = "processed-data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "record_id"
  range_key    = "timestamp"

  attribute {
    name = "record_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }
}

# ------------------------
# SNS Topic
# ------------------------
resource "aws_sns_topic" "notifications" {
  name = "data-processed-topic"
}

# ------------------------
# SQS Queue
# ------------------------
resource "aws_sqs_queue" "processing_queue" {
  name                      = "data-processed-queue"
  delay_seconds             = 60
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.unprocessed_data_queue_deadletter.arn
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue" "unprocessed_data_queue_deadletter" {
  name = "unprocessed-data-deadletter-queue"
}

resource "aws_sqs_queue_redrive_allow_policy" "unprocessed_data_redrive_allow_policy" {
  queue_url = aws_sqs_queue.unprocessed_data_queue_deadletter.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.processing_queue.arn]
  })
}

# ------------------------
# SNS → SQS Subscription
# ------------------------
resource "aws_sns_topic_subscription" "sns_to_sqs_sub" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.processing_queue.arn
}

# ------------------------
# SQS Policy allowing SNS publishing
# ------------------------
resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.processing_queue.id
  policy    = data.aws_iam_policy_document.sqs_policy.json
}

data "aws_iam_policy_document" "sqs_policy" {
  statement {
    sid       = "Allow-SNS-SendMessage"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.processing_queue.arn]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.notifications.arn]
    }
  }
}

# ------------------------
# Lambda Function
# ------------------------
resource "aws_lambda_function" "processor" {
  function_name = "process-uploaded-file"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = "lambda/function.zip"

  handler = "main.lambda_handler"
  runtime = "python3.11"
  role    = aws_iam_role.lambda_role.arn
  timeout = 10
}

# ------------------------
# S3 → Lambda Trigger
# ------------------------
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.data_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_bucket.arn
}
