variable "environment" {
  type        = string
  description = "The deployment environment (dev or live)"

  validation {
    condition     = contains(["dev", "live"], lower(var.environment))
    error_message = "Environment must be one of: dev or live."
  }
}

variable "law_resource_id" {
  description = "The resource ID of the Azure Log Analytics Workspace (LAW)"
  type        = string
  validation {
    condition     = can(regex("^/subscriptions/[a-f0-9-]+/resourceGroups/[a-zA-Z0-9-_]+/providers/Microsoft\\.OperationalInsights/workspaces/[a-zA-Z0-9-_]+$", var.law_resource_id))
    error_message = "The Azure Law resource ID must be in the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{lawName}'"
  }
}
