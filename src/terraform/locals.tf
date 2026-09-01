locals {
  environment = lower(var.environment)

  resource_group_name = "pims-reporting-${local.environment}-rg"

  workbook_name = "pims-reporting-${local.environment}-workbook"

  workbook_id = {
    "dev"  = "c2a4c3ba-e52d-4a43-ad31-1a9bdc1bbb32",
    "live" = "6b0de277-a58d-45b9-a7f2-019a35520700"
  }

  tags = {
    SERVICE          = "PIMS Reporting"
    ENVIRONMENT      = title(local.environment)
    RESPONSIBLE_TEAM = "IDAM"
    CALLOUT_TEAM     = "N/A"
    COST_CENTRE      = "P435"
    SERVICE_OWNER    = "Dee Bolt"
  }
}
