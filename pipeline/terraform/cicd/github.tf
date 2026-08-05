locals {
  repository_name = "idam-azure-dashboard-pims-reporting"
  repository_id   = "${var.github_owner}/${local.repository_name}"
}

data "github_repository" "this" {
  full_name = local.repository_id
}
