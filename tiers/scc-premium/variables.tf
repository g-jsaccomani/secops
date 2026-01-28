variable "parent_id" {
  type        = string
  description = "The parent resource where the folder will be created (e.g. 'organizations/123456789012' or 'folders/123456789012')"
}

variable "billing_account_id" {
  type        = string
  description = "The Google Cloud Billing Account ID (format: 'XXXXXX-XXXXXX-XXXXXX')"
}

variable "environment" {
  type        = string
  description = "Deployment environment name (e.g. 'dev', 'staging', 'prod', 'enterprise')"
  default     = "dev"
}

variable "region" {
  type        = string
  description = "Primary Google Cloud Region"
  default     = "us-central1"
}

variable "folder_name" {
  type        = string
  description = "Custom name for the created folder (leave empty for default name)"
  default     = ""
}

variable "custom_labels" {
  type        = map(string)
  description = "Additional custom labels to attach to created resources"
  default     = {}
}
