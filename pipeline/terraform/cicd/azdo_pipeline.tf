locals {
  pipeline_name = local.service_name
  pipeline_authorizations = merge(
    {
      github_endpoint = {
        type        = "endpoint"
        resource_id = data.azuredevops_serviceendpoint_github.this.id
        pipeline_id = azuredevops_build_definition.this.id
      }

      variable_group = {
        type        = "variablegroup"
        resource_id = azuredevops_variable_group.this.id
        pipeline_id = azuredevops_build_definition.this.id
      }

      azurerm_endpoint = {
        type        = "endpoint"
        resource_id = data.azuredevops_serviceendpoint_azurerm.this.id
        pipeline_id = azuredevops_build_definition.this.id
      }

      agent_queue = {
        type        = "queue"
        resource_id = data.azuredevops_agent_queue.this.id
        pipeline_id = azuredevops_build_definition.this.id
      }
    },
    { for env_key, env in azuredevops_environment.this : "env_${env_key}" => {
      type        = "environment"
      resource_id = env.id
      pipeline_id = azuredevops_build_definition.this.id
      }
    }
  )
}

resource "azuredevops_build_definition" "this" {
  project_id      = data.azuredevops_project.this.id
  name            = local.pipeline_name
  agent_pool_name = data.azuredevops_agent_queue.this.name
  path            = "\\${local.repository_name}"

  repository {
    repo_type             = "GitHub"
    repo_id               = github_repository.this.full_name
    branch_name           = "refs/heads/main"
    yml_path              = "pipeline/yaml/azure-dashboard-pipeline.yml"
    service_connection_id = data.azuredevops_serviceendpoint_github.this.service_endpoint_id
  }

  ci_trigger {
    use_yaml = true
  }

  pull_request_trigger {
    initial_branch = "refs/heads/main"
    use_yaml       = true
    forks {
      enabled       = false
      share_secrets = false
    }
  }
}

resource "azuredevops_pipeline_authorization" "this" {
  for_each = local.pipeline_authorizations

  project_id  = data.azuredevops_project.this.id
  type        = each.value.type
  resource_id = each.value.resource_id
  pipeline_id = each.value.pipeline_id
}

