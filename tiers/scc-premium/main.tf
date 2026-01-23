/**
 * Google Cloud SecOps - SCC Premium Tier Foundation
 * --------------------------------------------------
 * Deploys a dedicated Folder and Project with Security Command Center Premium Tier baseline,
 * Event Threat Detection, VMTD, CTD, SHA, BigQuery Continuous Export, and high-priority Pub/Sub alerts.
 *
 * Author: Joabson Saccomani (@jsaccomani)
 * License: Apache 2.0
 */

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "google" {
  region = var.region
}

# -----------------------------------------------------------------------------
# 1. RANDOM SUFFIX FOR RESOURCE UNIQUENESS
# -----------------------------------------------------------------------------
resource "random_id" "suffix" {
  byte_length = 3
}

# -----------------------------------------------------------------------------
# 2. DEDICATED SECOPS PREMIUM FOLDER
# -----------------------------------------------------------------------------
resource "google_folder" "scc_premium_folder" {
  display_name = var.folder_name != "" ? var.folder_name : "fldr-secops-premium-${var.environment}"
  parent       = var.parent_id # Format: "organizations/1234567890" or "folders/1234567890"
}

# -----------------------------------------------------------------------------
# 3. DEDICATED SECOPS PREMIUM PROJECT
# -----------------------------------------------------------------------------
resource "google_project" "scc_premium_project" {
  name            = "prj-secops-prem-${random_id.suffix.hex}"
  project_id      = "prj-secops-prem-${random_id.suffix.hex}"
  folder_id       = google_folder.scc_premium_folder.name
  billing_account = var.billing_account_id

  labels = merge(var.custom_labels, {
    tier        = "scc-premium"
    environment = var.environment
    managed_by  = "terraform"
  })
}

# -----------------------------------------------------------------------------
# 4. CORE & SCC PREMIUM ADVANCED APIS
# -----------------------------------------------------------------------------
locals {
  premium_apis = [
    "securitycenter.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudasset.googleapis.com",
    "storage.googleapis.com",
    "pubsub.googleapis.com",
    "bigquery.googleapis.com",
    "dlp.googleapis.com",
    "containersecurity.googleapis.com",
    "recommender.googleapis.com",
    "websecurityscanner.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com"
  ]
}

resource "google_project_service" "enabled_apis" {
  for_each           = toset(local.premium_apis)
  project            = google_project.scc_premium_project.project_id
  service            = each.key
  disable_on_destroy = false
}

# -----------------------------------------------------------------------------
# 5. SERVICE ACCOUNT FOR PREMIUM SECOPS AUTOMATION
# -----------------------------------------------------------------------------
resource "google_service_account" "secops_prem_sa" {
  project      = google_project.scc_premium_project.project_id
  account_id   = "sa-secops-prem-${var.environment}"
  display_name = "SecOps Premium Automation Service Account"
  description  = "Service account for managing SecOps Premium operations, threat analytics, and exports"
  depends_on   = [google_project_service.enabled_apis]
}

resource "google_project_iam_member" "sa_roles" {
  for_each = toset([
    "roles/securitycenter.admin",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/logging.viewer",
    "roles/monitoring.viewer",
    "roles/pubsub.publisher",
    "roles/pubsub.subscriber"
  ])
  project = google_project.scc_premium_project.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.secops_prem_sa.email}"
}

# -----------------------------------------------------------------------------
# 6. BIGQUERY DATASET FOR CONTINUOUS FINDINGS EXPORT
# -----------------------------------------------------------------------------
resource "google_bigquery_dataset" "scc_findings_dataset" {
  project     = google_project.scc_premium_project.project_id
  dataset_id  = "ds_scc_premium_findings_${replace(var.environment, "-", "_")}"
  description = "Centralized BigQuery dataset for Security Command Center Premium continuous findings analytics"
  location    = var.region

  labels = {
    tier        = "scc-premium"
    environment = var.environment
  }

  delete_contents_on_destroy = var.environment != "prod"
  depends_on                 = [google_project_service.enabled_apis]
}

# -----------------------------------------------------------------------------
# 7. PUB/SUB NOTIFICATION PIPELINE (HIGH/CRITICAL FINDINGS)
# -----------------------------------------------------------------------------
resource "google_pubsub_topic" "scc_prem_topic" {
  project = google_project.scc_premium_project.project_id
  name    = "top-scc-prem-high-findings-${var.environment}"
  labels = {
    tier = "scc-premium"
  }
  depends_on = [google_project_service.enabled_apis]
}

resource "google_pubsub_topic" "scc_prem_dlq" {
  project = google_project.scc_premium_project.project_id
  name    = "top-scc-prem-dlq-${var.environment}"
  labels = {
    tier = "scc-premium"
  }
  depends_on = [google_project_service.enabled_apis]
}

resource "google_pubsub_subscription" "scc_prem_sub" {
  project              = google_project.scc_premium_project.project_id
  name                 = "sub-scc-prem-high-findings-${var.environment}"
  topic                = google_pubsub_topic.scc_prem_topic.name
  ack_deadline_seconds = 60

  expiration_policy {
    ttl = "" # Never expire
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.scc_prem_dlq.id
    max_delivery_attempts = 5
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}

# -----------------------------------------------------------------------------
# 8. FOUNDATIONAL POSTURE & REPORTING STORAGE (GCS)
# -----------------------------------------------------------------------------
resource "google_storage_bucket" "posture_reports_bucket" {
  project                     = google_project.scc_premium_project.project_id
  name                        = "bkt-secops-prem-reports-${google_project.scc_premium_project.project_id}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.environment != "prod"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 180
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    tier        = "scc-premium"
    environment = var.environment
  }
  depends_on = [google_project_service.enabled_apis]
}
