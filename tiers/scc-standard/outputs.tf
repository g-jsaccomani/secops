output "folder_id" {
  description = "The ID of the newly created SecOps Standard Folder"
  value       = google_folder.scc_standard_folder.name
}

output "folder_display_name" {
  description = "The display name of the newly created SecOps Standard Folder"
  value       = google_folder.scc_standard_folder.display_name
}

output "project_id" {
  description = "The Project ID of the newly created SecOps Standard Project"
  value       = google_project.scc_standard_project.project_id
}

output "project_number" {
  description = "The numeric Project Number of the created project"
  value       = google_project.scc_standard_project.number
}

output "service_account_email" {
  description = "Email of the created SecOps Automation Service Account"
  value       = google_service_account.secops_sa.email
}

output "pubsub_topic_id" {
  description = "Pub/Sub topic ID for SCC standard findings notifications"
  value       = google_pubsub_topic.scc_findings_topic.id
}

output "pubsub_subscription_id" {
  description = "Pub/Sub subscription ID for SCC standard findings"
  value       = google_pubsub_subscription.scc_findings_sub.id
}

output "audit_bucket_name" {
  description = "GCS Bucket name for audit log archives"
  value       = google_storage_bucket.audit_bucket.name
}
