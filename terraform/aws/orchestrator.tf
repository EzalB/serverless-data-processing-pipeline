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
  
  image_uri     = "${aws_ecr_repository.orchestrator.repository_url}:${var.orchestrator_image_tag}"

  role    = aws_iam_role.orchestrator_lambda_role.arn
  timeout = 30
  memory_size = 512

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


