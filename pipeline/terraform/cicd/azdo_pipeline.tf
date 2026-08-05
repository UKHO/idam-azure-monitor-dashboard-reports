locals {
  pipeline_authorizations = {
    github = {
      type        = "endpoint"
      resource_id = data.azuredevops_serviceendpoint_github.this.id
      pipeline_id = azuredevops_build_definition.this.id
    }

    azure_subscription = {
      type        = "endpoint"
      resource_id = azuredevops_serviceendpoint_azurerm.this.id
      pipeline_id = azuredevops_build_definition.this.id
    }

    agent_queue = {
      type        = "queue"
      resource_id = data.azuredevops_agent_queue.this.id
      pipeline_id = azuredevops_build_definition.this.id
    }
  }
}

data "azuredevops_project" "this" {
  name = var.azure_devops_project_name
}

data "azuredevops_serviceendpoint_github" "this" { # Will need manually created part of the DevOps Project
  project_id            = data.azuredevops_project.this.id
  service_endpoint_name = var.azure_devops_service_endpoint_github_name
}

data "azuredevops_agent_queue" "this" { # Will need manually created part of the DevOps Project
  name       = var.azure_devops_agent_queue_name
  project_id = data.azuredevops_project.this.id
}

resource "azuredevops_build_definition" "this" {
  project_id = data.azuredevops_project.this.id
  name       = "${local.repository_name}.${local.service_name}"
  path       = "\\${local.service_name}"

  agent_pool_name = data.azuredevops_agent_queue.this.name

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = data.github_repository.this.id
    branch_name           = "refs/heads/main"
    yml_path              = "cicd/azure-dashboard-pipeline.yml"
    service_connection_id = data.azuredevops_serviceendpoint_github.this.id
  }
}

resource "azuredevops_pipeline_authorization" "this" {
  for_each = local.pipeline_authorizations

  project_id  = data.azuredevops_project.this.id
  type        = each.value.type
  resource_id = each.value.resource_id
  pipeline_id = each.value.pipeline_id
}

