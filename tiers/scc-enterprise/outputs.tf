output "folder_id" {
  description = "The ID of the newly created SecOps Enterprise Folder"
  value       = google_folder.scc_enterprise_folder.name
}

output "folder_display_name" {
  description = "The display name of the newly created SecOps Enterprise Folder"
  value       = google_folder.scc_enterprise_folder.display_name
}

output "project_id" {
  description = "The Project ID of the newly created SecOps Enterprise Project"
  value       = google_project.scc_enterprise_project.project_id
}

output "project_number" {
  description = "The numeric Project Number of the created project"
  value       = google_project.scc_enterprise_project.number
}

output "service_account_email" {
  description = "Email of the created SecOps Enterprise Automation Service Account"
  value       = google_service_account.secops_ent_sa.email
}

output "bigquery_lake_dataset_id" {
  description = "BigQuery Security Lake dataset ID for SecOps Enterprise"
  value       = google_bigquery_dataset.secops_security_lake.dataset_id
}

output "ingestion_topic_id" {
  description = "Pub/Sub topic ID for SecOps ingestion feeds"
  value       = google_pubsub_topic.secops_ingestion_topic.id
}

output "ingestion_subscription_id" {
  description = "Pub/Sub subscription ID for SecOps ingestion feeds"
  value       = google_pubsub_subscription.secops_ingestion_sub.id
}

output "soar_trigger_topic_id" {
  description = "Pub/Sub topic ID for triggering automated SOAR response playbooks"
  value       = google_pubsub_topic.soar_trigger_topic.id
}

output "ingestion_bucket_name" {
  description = "GCS Bucket name for raw log ingestion and evidence archive"
  value       = google_storage_bucket.secops_ingestion_bucket.name
}
