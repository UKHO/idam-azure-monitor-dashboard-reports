locals {
  repository_name  = "idam-azure-dashboard-pims-reporting"
  github_team_name = "IDAM"
}

data "github_app" "azure_pipelines" {
  slug = "azure-pipelines"
}

/*
data "github_app" "snyk_io_eu" {
  slug = "snyk-io-eu"
}
*/
