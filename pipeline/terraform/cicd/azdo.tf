data "azuredevops_project" "this" {
  name = var.azure_devops_project_name
}

data "azuredevops_serviceendpoint_github" "this" {
  project_id            = data.azuredevops_project.this.id
  service_endpoint_name = var.azure_devops_service_endpoint_github_name
}

data "azuredevops_serviceendpoint_azurerm" "this" {
  project_id            = data.azuredevops_project.this.id
  service_endpoint_name = var.azure_devops_service_endpoint_azurerm_name
}

data "azuredevops_agent_queue" "this" {
  name       = var.azure_devops_agent_queue_name
  project_id = data.azuredevops_project.this.id
}
