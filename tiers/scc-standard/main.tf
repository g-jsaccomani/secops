/**
 * Google Cloud SecOps - SCC Standard Tier Foundation
 * --------------------------------------------------
 * Deploys a dedicated Folder and Project with Security Command Center Standard Tier baseline,
 * foundational APIs, Pub/Sub finding notifications, and secure audit storage.
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
# 2. DEDICATED SECOPS FOLDER
# -----------------------------------------------------------------------------
resource "google_folder" "scc_standard_folder" {
  display_name = var.folder_name != "" ? var.folder_name : "fldr-secops-standard-${var.environment}"
  parent       = var.parent_id # Format: "organizations/1234567890" or "folders/1234567890"
}

# -----------------------------------------------------------------------------
# 3. DEDICATED SECOPS PROJECT
# -----------------------------------------------------------------------------
resource "google_project" "scc_standard_project" {
  name            = "prj-secops-std-${random_id.suffix.hex}"
  project_id      = "prj-secops-std-${random_id.suffix.hex}"
  folder_id       = google_folder.scc_standard_folder.name
  billing_account = var.billing_account_id

  labels = merge(var.custom_labels, {
    tier        = "scc-standard"
    environment = var.environment
    managed_by  = "terraform"
  })
}

# -----------------------------------------------------------------------------
# 4. CORE & SCC STANDARD APIS
# -----------------------------------------------------------------------------
locals {
  standard_apis = [
    "securitycenter.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudasset.googleapis.com",
    "storage.googleapis.com",
    "pubsub.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com"
  ]
}

resource "google_project_service" "enabled_apis" {
  for_each           = toset(local.standard_apis)
  project            = google_project.scc_standard_project.project_id
  service            = each.key
  disable_on_destroy = false
}

# -----------------------------------------------------------------------------
# 5. SERVICE ACCOUNT FOR SECOPS AUTOMATION & MANAGEMENT
# -----------------------------------------------------------------------------
resource "google_service_account" "secops_sa" {
  project      = google_project.scc_standard_project.project_id
  account_id   = "sa-secops-std-${var.environment}"
  display_name = "SecOps Standard Automation Service Account"
  description  = "Service account for managing SecOps Standard operations and findings notifications"
  depends_on   = [google_project_service.enabled_apis]
}

resource "google_project_iam_member" "sa_roles" {
  for_each = toset([
    "roles/securitycenter.viewer",
    "roles/logging.viewer",
    "roles/monitoring.viewer",
    "roles/pubsub.publisher",
    "roles/pubsub.subscriber"
  ])
  project = google_project.scc_standard_project.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.secops_sa.email}"
}

# -----------------------------------------------------------------------------
# 6. PUB/SUB NOTIFICATIONS FOR SCC FINDINGS
# -----------------------------------------------------------------------------
resource "google_pubsub_topic" "scc_findings_topic" {
  project = google_project.scc_standard_project.project_id
  name    = "top-scc-std-findings-${var.environment}"
  labels = {
    tier = "scc-standard"
  }
  depends_on = [google_project_service.enabled_apis]
}

resource "google_pubsub_subscription" "scc_findings_sub" {
  project              = google_project.scc_standard_project.project_id
  name                 = "sub-scc-std-findings-${var.environment}"
  topic                = google_pubsub_topic.scc_findings_topic.name
  ack_deadline_seconds = 60

  expiration_policy {
    ttl = "" # Never expire
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}

# -----------------------------------------------------------------------------
# 7. FOUNDATIONAL AUDIT STORAGE (GCS)
# -----------------------------------------------------------------------------
resource "google_storage_bucket" "audit_bucket" {
  project                     = google_project.scc_standard_project.project_id
  name                        = "bkt-secops-std-audit-${google_project.scc_standard_project.project_id}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.environment != "prod"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    tier        = "scc-standard"
    environment = var.environment
  }
  depends_on = [google_project_service.enabled_apis]
}
