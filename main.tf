terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Upload the function zip to a GCS bucket
resource "google_storage_bucket" "function_source" {
  name          = "${var.project_id}-function-code"
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "create_sharded_table.zip"
  bucket = google_storage_bucket.function_source.name
  source = "create_sharded_table.zip"
}

# Service account for the function
resource "google_service_account" "function_sa" {
  account_id   = "bq-shard-function-sa"
  display_name = "Service Account for BigQuery table sharding function"
}

# Grant BigQuery data editor role to the function
resource "google_project_iam_member" "bq_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

# Allow the function to be invoked via Cloud Run
resource "google_project_iam_member" "function_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

# Deploy the Cloud Function (Gen 2)
resource "google_cloudfunctions2_function" "create_shard" {
  name     = "create-sharded-table"
  location = var.region

  build_config {
    runtime     = "python310"
    entry_point = "create_sharded_table"
    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    min_instance_count     = 0
    max_instance_count     = 1
    available_memory       = "256M"
    timeout_seconds        = 60
    service_account_email  = google_service_account.function_sa.email
  }
}

# Lookup Cloud Run URL for the function
data "google_cloud_run_service" "function_endpoint" {
  name       = google_cloudfunctions2_function.create_shard.name
  location   = var.region
  depends_on = [google_cloudfunctions2_function.create_shard]
}

# Cloud Scheduler job to trigger function daily at 4 AM UTC
resource "google_cloud_scheduler_job" "create_sharded_table_job" {
  name        = "create-sharded-table-job"
  description = "Creates sharded table daily"
  schedule    = "0 4 * * *"
  time_zone   = "Etc/UTC"

  http_target {
    uri         = data.google_cloud_run_service.function_endpoint.status[0].url
    http_method = "POST"

    oidc_token {
      service_account_email = google_service_account.function_sa.email
      audience              = google_cloudfunctions2_function.create_shard.service_config[0].uri
 }
  }

  depends_on = [google_cloudfunctions2_function.create_shard]
}
