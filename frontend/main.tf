# frontend/main.tf

provider "google" {
  project = var.project_id
  region  = var.region
}

# フロントエンド用のArtifact Registry
resource "google_artifact_registry_repository" "frontend_repo" {
  location      = var.region
  repository_id = "frontend-repo"
  format        = "DOCKER"
}

# フロントエンド用のCloud Run Service Account
resource "google_service_account" "frontend_sa" {
  account_id   = "frontend-sa"
  display_name = "Frontend Service Account"
  description  = "Service account for frontend Cloud Run service"
}

# フロントエンド用のCloud Runサービス
resource "google_cloud_run_service" "frontend_service" {
  name     = "frontend-service"
  location = var.region

  template {
    metadata {
      annotations = {
        "client.knative.dev/user-image" = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.frontend_repo.repository_id}/frontend:latest"
        "run.googleapis.com/client-name" = "terraform"
        "run.googleapis.com/client-version" = "1.0.0"
        "run.googleapis.com/launch-stage" = "BETA"
        "timestamp" = timestamp()
      }
    }
    spec {
      service_account_name = google_service_account.frontend_sa.email
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.frontend_repo.repository_id}/frontend:latest"
        
        # バックエンドURLの設定
        env {
          name  = "BACKEND_URL"
          value = var.backend_url
        }

        ports {
          container_port = 8080
        }

        resources {
          limits = {
            memory = "256Mi"
            cpu    = "1000m"
          }
        }

        startup_probe {
          initial_delay_seconds = 10
          timeout_seconds      = 1
          period_seconds       = 3
          failure_threshold    = 3
          http_get {
            path = "/"
            port = 8080
          }
        }
      }
      container_concurrency = 80
      timeout_seconds      = 300
    }
  }
}

# パブリックアクセスの許可
resource "google_cloud_run_service_iam_member" "frontend_public" {
  service  = google_cloud_run_service.frontend_service.name
  location = google_cloud_run_service.frontend_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}