terraform {
  required_version = ">= 1.0"
  backend "local" {}
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.39.0"
    }
  }
}

provider "google" {
  project = var.project
  region = var.region
  credentials = file(var.credentials)
}

resource "google_project_service" "cloud_resource_manager" {
  project = var.project
  service = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = true
}

# Enable required services for the project
resource "google_project_service" "bigquery" {
  project = var.project
  service = "bigquery.googleapis.com"
  disable_dependent_services = true
  depends_on = [google_project_service.cloud_resource_manager]
}

resource "google_project_service" "storage" {
  project = var.project
  service = "storage.googleapis.com"
  disable_dependent_services = true
  depends_on = [google_project_service.cloud_resource_manager]
}

# Data Lake Bucket
resource "google_storage_bucket" "bucket_for_datalake" {
  name          = local.data_lake_bucket
  location      = var.region
  force_destroy = true


  # Optional, but recommended settings:
  storage_class = var.storage_class
  uniform_bucket_level_access = true
  depends_on = [google_project_service.storage]
}

# DWH
# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset
resource "google_bigquery_dataset" "reddit_post" {
  dataset_id = var.BQ_DATASET
  project    = var.project
  location   = var.region
  depends_on = [google_project_service.bigquery]

}

resource "google_bigquery_table" "post_ai" {
  dataset_id = var.BQ_DATASET
  table_id   = "post_ai"
  deletion_protection = false
  depends_on = [google_bigquery_dataset.reddit_post]

  time_partitioning {
    type = "DAY"
    field = "created_utc"
    require_partition_filter = false
  }

  clustering = ["reddit"]

  schema = jsonencode([
    {
      "name": "id",
      "type": "STRING",
      "mode": "NULLABLE"
    },
    {
      "name": "subreddit",
      "type": "STRING",
      "mode": "NULLABLE"
    },
    {
      "name": "author",
      "type": "STRING",
      "mode": "NULLABLE"
    },
    {
      "name": "subreddit_subscriber",
      "type": "INT64",
      "mode": "NULLABLE"
    },
    {
      "name": "selftext",
      "type": "STRING",
      "mode": "NULLABLE"
    },
    {
      "name": "title",
      "type": "STRING",
      "mode": "NULLABLE"
    },
    {
      "name": "created_utc",
      "type": "TIMESTAMP",
      "mode": "NULLABLE"
    },
    {
      "name": "url",
      "type": "STRING",
      "mode": "NULLABLE"
    },
  ])
}


provider "confluent" {
  cloud_api_key    = var.cloud_api_key
  cloud_api_secret = var.cloud_api_secret
}

resource "confluent_kafka_cluster" "main" {
  display_name = "cluster_reddit"
  availability = "SINGLE_ZONE"
  cloud        = "GCP"
  region       = "asia-southeast2"
  basic {}

  environment {
//    id = confluent.environment.basic.id
    id = var.environment_id
  }

  lifecycle {
    prevent_destroy = false
  }
}

data "confluent_kafka_cluster" "main" {
  id = confluent_kafka_cluster.main.id

  environment {
    id = var.environment_id
  }
}

resource "confluent_service_account" "app-manager" {
  display_name = "app-${var.topic_name}-manager"
  description  = "Service account to manage ${confluent_kafka_cluster.main.id} Kafka cluster"

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = data.confluent_kafka_cluster.main.rbac_crn
}

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by ${confluent_service_account.app-manager.display_name} service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.main.id
    api_version = data.confluent_kafka_cluster.main.api_version
    kind        = data.confluent_kafka_cluster.main.kind

    environment {
      id = var.environment_id
    }
  }

  depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin
  ]
}



resource "confluent_kafka_topic" "main" {
  kafka_cluster {
    id = confluent_kafka_cluster.main.id
  }

  topic_name    = var.topic_name
  rest_endpoint = data.confluent_kafka_cluster.main.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}
