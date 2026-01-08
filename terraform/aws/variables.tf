variable "region" {
  description = "AWS Region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_id" {
  description = "Project name prefix for AWS resources"
  type        = string
  default     = "serverless-arch"
}

variable "orchestrator_bootstrap_image" {
  description = "Initial docker image tag for Lambda creation for AWS Java orchestrator"
  type        = string
  default     = "bootstrap"
}