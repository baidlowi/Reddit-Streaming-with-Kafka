output "kafka_api_key_id" {
  description = "Kafka API Key ID"
  value       = confluent_api_key.app-manager-kafka-api-key.id
}

output "kafka_api_key_secret" {
  description = "Kafka API Key Secret"
  value       = confluent_api_key.app-manager-kafka-api-key.secret
  sensitive   = true
}

output "kafka_endpoint" {
  description = "Kafka Endpoint"
  value       = data.reddit_cluster.main.bootstrap_endpoint
  sensitive   = true
}

output "gcp_project_id" {
  description = "Google Project ID"
  value       = var.project
}
