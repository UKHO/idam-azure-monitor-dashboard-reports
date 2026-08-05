locals {
  environment_securityrole_assignments = {
    (data.azuredevops_group.release_admins.origin_id)      = "Administrator"
    (data.azuredevops_group.build_admins.origin_id)        = "User"
    (data.azuredevops_group.contributors.origin_id)        = "Reader"
    (data.azuredevops_group.project_admins.origin_id)      = "Administrator"
    (data.azuredevops_group.project_valid_users.origin_id) = "Reader"
  }
  environment_name = local.service_name
}

resource "azuredevops_environment" "this" {
  project_id  = data.azuredevops_project.this.id
  name        = local.environment_name
  description = "Environment for ${local.service_name}"
}

resource "azuredevops_check_approval" "azdo_env" {
  project_id           = data.azuredevops_project.this.id
  target_resource_id   = azuredevops_environment.this.id
  target_resource_type = "environment"

  approvers = [
    data.azuredevops_group.build_admins.id,
    data.azuredevops_group.release_admins.id
  ]

  instructions               = "Please review and approve the environment for ${local.service_name}."
  minimum_required_approvers = 1
  requester_can_approve      = false
  timeout                    = local.check_approval_timeout
}

resource "azuredevops_securityrole_assignment" "this" {
  for_each = local.environment_securityrole_assignments

  scope       = "distributedtask.environmentreferencerole"
  resource_id = "${data.azuredevops_project.this.id}_${azuredevops_environment.this.id}"
  identity_id = each.key
  role_name   = each.value
}
