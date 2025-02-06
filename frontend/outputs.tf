output "frontend_url" {
  value = google_cloud_run_service.frontend_service.status[0].url
}

output "frontend_repository" {
  value = google_artifact_registry_repository.frontend_repo.name
}
