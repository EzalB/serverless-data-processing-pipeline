terraform {
  backend "gcs" {
    bucket = "terraform-state-bucket-tenacious-moon-447908-u4"
    prefix = "gcp/serverless-infra"
  }
}
