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

  environment {
    variables = {
      TABLE_NAME    = aws_dynamodb_table.processed_data.name
      SNS_TOPIC_ARN = aws_sns_topic.notifications.arn
    }
  }
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

# ------------------------
# ECR Repository
# ------------------------
resource "aws_ecr_repository" "orchestrator" {
  name                 = "aws-java-orchestrator"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "orchestrator" {
  repository = aws_ecr_repository.orchestrator.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "tagged"
          tagPrefixList = ["sha-"]
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ------------------------
# IAM Role for Lambda
# ------------------------
resource "aws_iam_role" "orchestrator_lambda_role" {
  name = "aws-java-orchestrator-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "orchestrator_lambda_policy" {
  role = aws_iam_role.orchestrator_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.processing_queue.arn
      }
    ]
  })
}

# ------------------------
# Lambda Function (Container)
# ------------------------
resource "aws_lambda_function" "orchestrator" {
  function_name = "aws-java-orchestrator"
  package_type  = "Image"
  
  image_uri     = "${aws_ecr_repository.orchestrator.repository_url}:${var.orchestrator_bootstrap_image}"

  role          = aws_iam_role.orchestrator_lambda_role.arn
  timeout       = 30
  memory_size   = 512

  environment {
    variables = {
      ENV = "prod"
    }
  }

  depends_on = [
    aws_iam_role_policy.orchestrator_lambda_policy
  ]
}

# ------------------------
# Lambda Alias
# ------------------------
resource "aws_lambda_alias" "prod" {
  name             = "prod"
  function_name    = aws_lambda_function.orchestrator.function_name
  function_version = "$LATEST"
}



# ------------------------
# SQS → Java Orchestrator Trigger
# ------------------------
resource "aws_lambda_event_source_mapping" "orchestrator_sqs_trigger" {
  event_source_arn = aws_sqs_queue.processing_queue.arn
  function_name    = aws_lambda_function.orchestrator.arn

  batch_size       = 5
  enabled          = true
}
