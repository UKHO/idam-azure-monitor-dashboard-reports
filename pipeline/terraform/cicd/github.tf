locals {
  repository_name = "idam-azure-dashboard-pims-reporting"
  repository_id   = "${var.github_owner}/${local.repository_name}"
  # github_team_name = "team-idam"
}

data "github_repository" "this" {
  full_name = local.repository_id
}

data "github_app" "azure_pipelines" {
  slug = "azure-pipelines"
}

/*
data "github_app" "snyk_io_eu" {
  slug = "snyk-io-eu"
}
*/
