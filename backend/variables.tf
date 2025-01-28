variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Region for GCP resources"
  type        = string
  default     = "asia-northeast1"
}

variable "api_token" {
  description = "API authentication token"
  type        = string
  sensitive   = true
}