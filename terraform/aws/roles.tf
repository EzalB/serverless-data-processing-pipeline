# ------------------------
# Lambda IAM Role
# ------------------------
resource "aws_iam_role" "lambda_role" {
  name = "lambda_processor_role"

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

# ------------------------
# Custom IAM Policy: Uploader
# ------------------------
resource "aws_iam_policy" "uploader_policy" {
  name = "UploaderPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "UploaderObjectAccess"
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.data_bucket.arn,
          "${aws_s3_bucket.data_bucket.arn}/*"
        ]
      },
      {
        Sid      = "UploaderBucketAccess"
        Effect   = "Allow"
        Action   = [
          "s3:ListBucket",
          "s3:ListBucketVersions",
          "s3:GetBucketAcl",
          "s3:GetBucketTagging"
        ]
        Resource = [
          aws_s3_bucket.data_bucket.arn,
          "${aws_s3_bucket.data_bucket.arn}/*"
        ]
      }
    ]
  })
}

# ------------------------
# Custom IAM Policy: Processor
# ------------------------
resource "aws_iam_policy" "processor_policy" {
  name = "ProcessorPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:UpdateItem"]
        Resource = aws_dynamodb_table.processed_data.arn
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.notifications.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:*"]
        Resource = "*"
      }
    ]
  })
}

# ------------------------
# Attach Processor policy to Lambda role
# ------------------------
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.processor_policy.arn
}
