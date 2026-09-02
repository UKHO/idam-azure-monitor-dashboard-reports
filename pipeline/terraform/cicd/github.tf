locals {
  repository_name  = "idam-azure-monitor-dashboard-reports"
  github_team_name = "IDAM"
}

data "github_app" "azure_pipelines" {
  slug = "azure-pipelines"
}
