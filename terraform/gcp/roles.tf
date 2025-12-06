# ------------------------
# Custom Roles
# ------------------------
resource "google_project_iam_custom_role" "uploader" {
  role_id     = "uploaderRole"
  title       = "Uploader Role"
  description = "Can only write to bucket"
  permissions = [
    "storage.objects.create",
    "storage.objects.get",
    "storage.objects.list"
  ]
}

resource "google_project_iam_custom_role" "processor" {
  role_id     = "processorRole"
  title       = "Processor Role"
  description = "For Cloud Function processing"
  permissions = [
    "storage.objects.get",
    "storage.objects.list",
    "bigquery.tables.updateData",
    "bigquery.tables.get",
    "bigquery.datasets.get",
    "bigquery.jobs.create",
    "pubsub.topics.publish",
    "logging.logEntries.create"
  ]
}

resource "google_project_iam_custom_role" "analyst" {
  role_id     = "analystRole"
  title       = "Analyst Role"
  description = "Can query BigQuery"
  permissions = [
    "bigquery.jobs.create",
    "bigquery.tables.getData",
    "bigquery.datasets.get",
    "bigquery.tables.get",
    "bigquery.tables.list"
  ]
}

# ------------------------
# Bind Roles to Service Accounts
# ------------------------
resource "google_project_iam_member" "uploader_bind" {
  project = var.project_id
  role   = google_project_iam_custom_role.uploader.name
  member = "serviceAccount:${google_service_account.uploader_sa.email}"
}

resource "google_project_iam_member" "processor_bind" {
  project = var.project_id
  role   = google_project_iam_custom_role.processor.name
  member = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_project_iam_member" "analyst_bind" {
  project = var.project_id
  role   = google_project_iam_custom_role.analyst.name
  member = "serviceAccount:${google_service_account.analyst_sa.email}"
}
