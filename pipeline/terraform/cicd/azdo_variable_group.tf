resource "azuredevops_variable_group" "this" {
  project_id   = data.azuredevops_project.this.id
  name         = "${local.service_name}-shared"
  description  = "Variables for all environments."
  allow_access = false

  variable {
    name         = "law_resource_id"
    secret_value = var.law_resource_id
    is_secret    = true
  }

  variable {
    name  = "azure_subscription_id"
    value = var.azure_subscription_id
  }
}

resource "azuredevops_check_approval" "azdo_variable_group" {
  project_id           = data.azuredevops_project.this.id
  target_resource_id   = azuredevops_variable_group.this.id
  target_resource_type = "variablegroup"

  approvers = [
    data.azuredevops_group.build_admins.id,
    data.azuredevops_group.release_admins.id
  ]

  instructions               = "Please review and approve the variable group for ${local.service_name}."
  minimum_required_approvers = 1
  requester_can_approve      = true
  timeout                    = 60
}
