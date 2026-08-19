locals {
  environment_securityrole_assignments = {
    (data.azuredevops_group.release_admins.origin_id)      = "Administrator"
    (data.azuredevops_group.build_admins.origin_id)        = "User"
    (data.azuredevops_group.contributors.origin_id)        = "Reader"
    (data.azuredevops_group.project_admins.origin_id)      = "Administrator"
    (data.azuredevops_group.project_valid_users.origin_id) = "Reader"
  }

  environment_names = {
    dev = {
      name = "${local.service_name}-dev"
      approvers = [
        data.azuredevops_group.build_admins.origin_id,
      ]
      timeout = 30
    },
    live = {
      name = "${local.service_name}-live"
      approvers = [
        data.azuredevops_group.build_admins.origin_id,
        data.azuredevops_group.release_admins.origin_id
      ]
      timeout = 120
    }
  }
}

resource "azuredevops_environment" "this" {
  for_each = local.environment_names

  project_id  = data.azuredevops_project.this.id
  name        = each.value.name
  description = "Environment for ${local.service_name}"
}

resource "azuredevops_check_approval" "azdo_env" {
  for_each = local.environment_names

  project_id           = data.azuredevops_project.this.id
  target_resource_id   = azuredevops_environment.this[each.value.name].id
  target_resource_type = "environment"

  approvers = each.value.approvers

  instructions               = "Please review and approve the environment for ${local.service_name}."
  minimum_required_approvers = 1
  requester_can_approve      = true
  timeout                    = each.value.timeout
}

locals {
  env_ids = { for k, v in azuredevops_environment.this : k => v.id }

  env_role_assignments = {
    for pair in flatten([
      for env_key, env_id in local.env_ids : [
        for identity, role in local.environment_securityrole_assignments : {
          key         = "${env_key}_${identity}"
          resource_id = "${data.azuredevops_project.this.id}_${env_id}"
          identity_id = identity
          role_name   = role
        }
      ]
      ]) : pair.key => {
      resource_id = pair.resource_id
      identity_id = pair.identity_id
      role_name   = pair.role_name
    }
  }
}

resource "azuredevops_securityrole_assignment" "this" {
  for_each = local.env_role_assignments

  scope       = "distributedtask.environmentreferencerole"
  resource_id = each.value.resource_id
  identity_id = each.value.identity_id
  role_name   = each.value.role_name
}
