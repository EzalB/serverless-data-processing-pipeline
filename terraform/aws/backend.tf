terraform {
  backend "s3" {
    bucket         = "tf-state-serverless-pipeline"
    key            = "aws/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
