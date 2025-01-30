provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "my_repo" {
  location      = var.region
  repository_id = "my-app-repo"
  format        = "DOCKER"
}

# Vertex AI用のサービスアカウント
resource "google_service_account" "vertex_ai_sa" {
  account_id   = "vertex-ai-sa"
  display_name = "Vertex AI Service Account"
  description  = "Service account for Vertex AI API access"
}

# Cloud Run用のサービスアカウント
resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"
  description  = "Service account for Cloud Run service"
}

# Vertex AI用の権限設定
resource "google_project_iam_member" "vertex_ai_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.vertex_ai_sa.email}"
}

# Cloud Run用のVertex AI権限設定
resource "google_project_iam_member" "cloud_run_vertex_ai" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_cloud_run_service" "my_service" {
  name     = "my-app-service"
  location = var.region

  template {
    metadata {
      annotations = {
        "client.knative.dev/user-image" = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.my_repo.repository_id}/app:latest"
        "run.googleapis.com/client-name" = "terraform"
        "run.googleapis.com/client-version" = "1.0.0"
        "run.googleapis.com/launch-stage" = "BETA"
        "timestamp" = timestamp()
      }
    }
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.my_repo.repository_id}/app:latest"
        env {
            name = "TOKEN"
            value = var.api_token
        }
        ports {
          container_port = 8080
        }

        resources {
          limits = {
            memory = "512Mi"
            cpu    = "1000m"
          }
        }

        startup_probe {
          initial_delay_seconds = 10
          timeout_seconds       = 1
          period_seconds        = 3
          failure_threshold     = 3
          tcp_socket {
            port = 8080
          }
        }
      }
      container_concurrency = 80
      timeout_seconds       = 300
    }
  }
}

resource "google_cloud_run_service_iam_member" "public" {
  service  = google_cloud_run_service.my_service.name
  location = google_cloud_run_service.my_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# サービスアカウントキーの作成
resource "google_service_account_key" "vertex_ai_key" {
  service_account_id = google_service_account.vertex_ai_sa.name
}

# サービスアカウントキーをローカルファイルに出力
resource "local_file" "vertex_ai_key_file" {
  content  = base64decode(google_service_account_key.vertex_ai_key.private_key)
  filename = "vertex-ai-service-account.json"
}

