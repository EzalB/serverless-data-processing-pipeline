variable "region" {
  description = "AWS Region for resources"
  type        = "string"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix for AWS resources"
  type        = string
  default     = "serverless-arch"
}