# ------------------------
# Storage bucket for uploads
# ------------------------
resource "google_storage_bucket" "data_bucket" {
  name          = "${var.project_id}-data-bucket"
  location      = var.region
  force_destroy = true
}

# ------------------------
# BigQuery dataset & table
# ------------------------
resource "google_bigquery_dataset" "dataset" {
  dataset_id = "serverless_processing_dataset"
  location   = var.region
}

resource "google_bigquery_table" "table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "processed_data"
  schema     = file("${path.module}/../cloud-function/schema.json")
}

# ------------------------
# Pub/Sub topic for notifications
# ------------------------
resource "google_pubsub_topic" "topic" {
  name = "data-processed-topic"
}

# ------------------------
# Service Accounts
# ------------------------
resource "google_service_account" "function_sa" {
  account_id   = "function-processor-sa"
  display_name = "Cloud Function Processor Service Account"
}

resource "google_service_account" "uploader_sa" {
  account_id   = "uploader-sa"
  display_name = "Uploader Service Account"
}

resource "google_service_account" "analyst_sa" {
  account_id   = "analyst-sa"
  display_name = "Analyst Service Account"
}

# ------------------------
# Cloud Function (2nd gen)
# ------------------------
resource "google_storage_bucket" "function_bucket" {
  name          = "${var.project_id}-function-code"
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = "${path.module}/../cloud-function/function-source.zip"
}

resource "google_cloudfunctions2_function" "function" {
  name        = "process-uploaded-file"
  location    = var.region
  description = "Triggered by GCS upload, validates and loads data into BigQuery"

  build_config {
    runtime     = "python311"
    entry_point = "process_file"
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    service_account_email = google_service_account.function_sa.email
    max_instance_count    = 3
  }

  event_trigger {
    event_type = "google.cloud.storage.object.v1.finalized"
    trigger_region = var.region
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.data_bucket.name
    }
  }
}

