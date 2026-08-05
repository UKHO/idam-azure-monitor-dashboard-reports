variable "azure_devops_org_service_url" {
  description = "The Azure DevOps organization service URL"
  type        = string
  validation {
    condition     = can(regex("^https://dev.azure.com/[^/]+$", var.azure_devops_org_service_url))
    error_message = "The Azure DevOps organization service URL must be in the format 'https://dev.azure.com/{organization}'"
  }
}

variable "github_owner" {
  description = "The GitHub owner (user or organization)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.github_owner))
    error_message = "The GitHub owner must only contain alphanumeric characters and hyphens."
  }
}

variable "azure_devops_project_name" {
  description = "The name of the Azure DevOps project"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_ ]+$", var.azure_devops_project_name))
    error_message = "The Azure DevOps project name must only contain alphanumeric characters, hyphens, underscores, and spaces."
  }
}

variable "azure_devops_service_endpoint_azurerm_name" {
  description = "The name of the Azure DevOps service endpoint for Azure Resource Manager"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_ ]+$", var.azure_devops_service_endpoint_azurerm_name))
    error_message = "The Azure DevOps service endpoint name must only contain alphanumeric characters, hyphens, underscores, and spaces."
  }
}

variable "azure_devops_service_endpoint_github_name" {
  description = "The name of the Azure DevOps service endpoint for GitHub"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_ ]+$", var.azure_devops_service_endpoint_github_name))
    error_message = "The Azure DevOps service endpoint name must only contain alphanumeric characters, hyphens, underscores, and spaces."
  }
}

variable "azure_devops_agent_queue_name" {
  description = "The name of the Azure DevOps agent queue"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_ ]+$", var.azure_devops_agent_queue_name))
    error_message = "The Azure DevOps agent queue name must only contain alphanumeric characters, hyphens, underscores, and spaces."
  }
}

variable "law_resource_id" {
  description = "The resource ID of the Azure Law resource"
  type        = string
  validation {
    condition     = can(regex("^/subscriptions/[a-f0-9-]+/resourceGroups/[a-zA-Z0-9-_]+/providers/Microsoft.Law/laws/[a-zA-Z0-9-_]+$", var.law_resource_id))
    error_message = "The Azure Law resource ID must be in the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Law/laws/{lawName}'"
  }
}

variable "azure_subscription_id" {
  description = "The Azure subscription ID"
  type        = string
  validation {
    condition     = can(regex("^[a-f0-9-]+$", var.azure_subscription_id))
    error_message = "The Azure subscription ID must be a valid GUID."
  }
}
