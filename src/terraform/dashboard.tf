resource "azurerm_application_insights_workbook" "this" {
  name                = local.workbook_id[local.environment]
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  display_name        = local.workbook_name
  data_json           = templatefile("${path.module}/pims_dashboard.json.tmpl", { law_resource_id = var.law_resource_id })
  tags                = local.tags
}
