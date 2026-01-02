/**
 * Google Cloud SecOps - SCC Enterprise Tier Foundation
 * ----------------------------------------------------
 * Deploys a dedicated Folder and Project with Security Command Center Enterprise Tier & Google SecOps
 * (Chronicle SIEM & SOAR) convergence baseline, unified multi-cloud ingestion feeds, security lake, and playbook triggers.
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
# 2. DEDICATED SECOPS ENTERPRISE FOLDER
# -----------------------------------------------------------------------------
resource "google_folder" "scc_enterprise_folder" {
  display_name = var.folder_name != "" ? var.folder_name : "fldr-secops-enterprise-${var.environment}"
  parent       = var.parent_id # Format: "organizations/1234567890" or "folders/1234567890"
}

# -----------------------------------------------------------------------------
# 3. DEDICATED SECOPS ENTERPRISE PROJECT
# -----------------------------------------------------------------------------
resource "google_project" "scc_enterprise_project" {
  name            = "prj-secops-ent-${random_id.suffix.hex}"
  project_id      = "prj-secops-ent-${random_id.suffix.hex}"
  folder_id       = google_folder.scc_enterprise_folder.name
  billing_account = var.billing_account_id

  labels = merge(var.custom_labels, {
    tier        = "scc-enterprise"
    environment = var.environment
    managed_by  = "terraform"
  })
}

# -----------------------------------------------------------------------------
# 4. UNIFIED SECOPS & SCC ENTERPRISE APIS
# -----------------------------------------------------------------------------
locals {
  enterprise_apis = [
    "securitycenter.googleapis.com",
    "chronicle.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudasset.googleapis.com",
    "storage.googleapis.com",
    "pubsub.googleapis.com",
    "bigquery.googleapis.com",
    "dlp.googleapis.com",
    "containeranalysis.googleapis.com",
    "containersecurity.googleapis.com",
    "recommender.googleapis.com",
    "websecurityscanner.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com"
  ]
}

resource "google_project_service" "enabled_apis" {
  for_each           = toset(local.enterprise_apis)
  project            = google_project.scc_enterprise_project.project_id
  service            = each.key
  disable_on_destroy = false
}

# -----------------------------------------------------------------------------
# 5. SERVICE ACCOUNT FOR UNIFIED SECOPS & SOAR ORCHESTRATION
# -----------------------------------------------------------------------------
resource "google_service_account" "secops_ent_sa" {
  project      = google_project.scc_enterprise_project.project_id
  account_id   = "sa-secops-ent-${var.environment}"
  display_name = "SecOps Enterprise & SOAR Orchestration Service Account"
  description  = "Service account for unified SecOps Enterprise operations, Chronicle feeds, and SOAR playbooks"
  depends_on   = [google_project_service.enabled_apis]
}

resource "google_project_iam_member" "sa_roles" {
  for_each = toset([
    "roles/securitycenter.admin",
    "roles/bigquery.admin",
    "roles/logging.viewer",
    "roles/monitoring.viewer",
    "roles/pubsub.admin",
    "roles/storage.objectAdmin"
  ])
  project = google_project.scc_enterprise_project.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.secops_ent_sa.email}"
}

# -----------------------------------------------------------------------------
# 6. UNIFIED TELEMETRY INGESTION PIPELINE (PUBSUB & FEEDS)
# -----------------------------------------------------------------------------
resource "google_pubsub_topic" "secops_ingestion_topic" {
  project = google_project.scc_enterprise_project.project_id
  name    = "top-secops-ent-ingestion-${var.environment}"
  labels = {
    tier = "scc-enterprise"
  }
  depends_on = [google_project_service.enabled_apis]
}

resource "google_pubsub_subscription" "secops_ingestion_sub" {
  project              = google_project.scc_enterprise_project.project_id
  name                 = "sub-secops-ent-ingestion-${var.environment}"
  topic                = google_pubsub_topic.secops_ingestion_topic.name
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
# 7. SOAR AUTOMATION & INCIDENT RESPONSE TRIGGER TOPIC
# -----------------------------------------------------------------------------
resource "google_pubsub_topic" "soar_trigger_topic" {
  project = google_project.scc_enterprise_project.project_id
  name    = "top-secops-ent-soar-triggers-${var.environment}"
  labels = {
    tier = "scc-enterprise"
  }
  depends_on = [google_project_service.enabled_apis]
}

resource "google_pubsub_subscription" "soar_trigger_sub" {
  project              = google_project.scc_enterprise_project.project_id
  name                 = "sub-secops-ent-soar-triggers-${var.environment}"
  topic                = google_pubsub_topic.soar_trigger_topic.name
  ack_deadline_seconds = 120

  expiration_policy {
    ttl = ""
  }
}

# -----------------------------------------------------------------------------
# 8. BIGQUERY ENTERPRISE SECURITY LAKE
# -----------------------------------------------------------------------------
resource "google_bigquery_dataset" "secops_security_lake" {
  project     = google_project.scc_enterprise_project.project_id
  dataset_id  = "ds_secops_enterprise_lake_${replace(var.environment, "-", "_")}"
  description = "Centralized BigQuery Security Lake for SecOps Enterprise telemetry, UDM search archives, and compliance audits"
  location    = var.region

  labels = {
    tier        = "scc-enterprise"
    environment = var.environment
  }

  delete_contents_on_destroy = var.environment != "prod"
  depends_on                 = [google_project_service.enabled_apis]
}

# -----------------------------------------------------------------------------
# 9. GCS INGESTION & SECURE EVIDENCE REPOSITORY
# -----------------------------------------------------------------------------
resource "google_storage_bucket" "secops_ingestion_bucket" {
  project                     = google_project.scc_enterprise_project.project_id
  name                        = "bkt-secops-ent-ingestion-${google_project.scc_enterprise_project.project_id}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.environment != "prod"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    tier        = "scc-enterprise"
    environment = var.environment
  }
  depends_on = [google_project_service.enabled_apis]
}
