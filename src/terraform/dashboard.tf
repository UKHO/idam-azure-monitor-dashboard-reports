locals {
  pims_dashboard_workbook_id = {
    "dev"  = "c2a4c3ba-e52d-4a43-ad31-1a9bdc1bbb32",
    "live" = "6b0de277-a58d-45b9-a7f2-019a35520700"
  }

  workbooks = {
    (local.pims_dashboard_workbook_id[local.environment]) = {
      display_name       = local.environment != "live" ? "PIMs Reporting (${var.environment})" : "PIMs Reporting"
      template_file_path = "pims_dashboard.json.tmpl"
      variables = {
        law_resource_id = var.law_resource_id
      }
    }
  }
}

resource "azurerm_application_insights_workbook" "this" {
  for_each = local.workbooks

  name                = each.key
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  display_name        = each.value.display_name
  data_json           = templatefile("${path.module}/dashboard_templates/${each.value.template_file_path}", each.value.variables)
  tags                = local.tags
}
