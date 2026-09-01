locals {
  environment = lower(var.environment)

  resource_group_name = "azure-monitor-dashboard-reports-${local.environment}-rg"

  tags = {
    SERVICE          = "Azure Monitor Dashboard Reports"
    ENVIRONMENT      = title(local.environment)
    RESPONSIBLE_TEAM = "IDAM"
    CALLOUT_TEAM     = "N/A"
    COST_CENTRE      = "P435"
    SERVICE_OWNER    = "Dee Bolt"
  }
}
