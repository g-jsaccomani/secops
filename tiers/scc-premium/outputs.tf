output "folder_id" {
  description = "The ID of the newly created SecOps Premium Folder"
  value       = google_folder.scc_premium_folder.name
}

output "folder_display_name" {
  description = "The display name of the newly created SecOps Premium Folder"
  value       = google_folder.scc_premium_folder.display_name
}

output "project_id" {
  description = "The Project ID of the newly created SecOps Premium Project"
  value       = google_project.scc_premium_project.project_id
}

output "project_number" {
  description = "The numeric Project Number of the created project"
  value       = google_project.scc_premium_project.number
}

output "service_account_email" {
  description = "Email of the created SecOps Premium Automation Service Account"
  value       = google_service_account.secops_prem_sa.email
}

output "bigquery_dataset_id" {
  description = "BigQuery dataset ID for continuous findings analytics"
  value       = google_bigquery_dataset.scc_findings_dataset.dataset_id
}

output "pubsub_topic_id" {
  description = "Pub/Sub topic ID for SCC Premium high/critical finding alerts"
  value       = google_pubsub_topic.scc_prem_topic.id
}

output "pubsub_subscription_id" {
  description = "Pub/Sub subscription ID for high-priority finding alerts"
  value       = google_pubsub_subscription.scc_prem_sub.id
}

output "posture_reports_bucket_name" {
  description = "GCS Bucket name for security posture and compliance reports"
  value       = google_storage_bucket.posture_reports_bucket.name
}
