variable "cloud_api_key" {
  description = "Confluent Cloud API Key"
  type        = string
  default     = "<ADD VALUE>"
}

variable "cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
  default     = "<ADD HERE>"
}

variable "environment_id" {
  description = "The ID Environment that the Kafka cluster belongs to of the form 'env-'"
  type        = string
  default     = "<ADD HERE>"
}

variable "topic_name" {
  description = "Name Kafka topics"
  default = "reddit_post"
}

locals {
  data_lake_bucket = "<ADD HERE>"
}

variable "project" {
  description = "Project ID"
  default = "<ADD HERE>"
}

variable "credentials" {
  description = "Google cloud credentials file"
  default = "./google-services.json"
}

variable "region" {
  description = "Region for GCP resources"
  default = "asia-southeast2"
  type = string
}

variable "storage_class" {
  description = "Storage class type for bucket"
  default = "STANDARD"
}

variable "BQ_DATASET" {
  description = "BigQuery Dataset"
  type = string
  default = "reddit_post"
}
