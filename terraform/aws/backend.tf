terraform {
  backend "s3" {
    bucket         = "serverless-pipeline-tf-state"
    key            = "aws/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "serverless-terraform-locks"
    encrypt        = true
  }
}
