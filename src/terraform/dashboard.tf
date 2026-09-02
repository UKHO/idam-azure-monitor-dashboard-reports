locals {
  questionable_pim_report_workbook_id = {
    "dev"  = "c2a4c3ba-e52d-4a43-ad31-1a9bdc1bbb32",
    "live" = "6b0de277-a58d-45b9-a7f2-019a35520700"
  }

  fido2_adoption_report_workbook_id = {
    "dev"  = "472ac27d-dfbd-4897-afda-0de8bed6f992",
    "live" = "d740b6e1-b198-4cee-adba-6a87e32c44f1"
  }

  out_of_hours_activations_report_workbook_id = {
    "dev"  = "18509edb-e68d-4ee7-9f57-46365929ce33",
    "live" = "b50004f9-8aca-491d-aaca-ef5704474839"
  }

  workbooks = {
    (local.questionable_pim_report_workbook_id[local.environment]) = {
      display_name       = "Questionable PIM Assignments Report"
      template_file_path = "questionable_pim_assignments_report.json.tmpl"
      variables = {
        law_resource_id = var.law_resource_id
      }
    },
    (local.fido2_adoption_report_workbook_id[local.environment]) = {
      display_name       = "FIDO2 Adoption Report"
      template_file_path = "fido2_adoption_report.json.tmpl"
      variables = {
        law_resource_id = var.law_resource_id
      }
    },
    (local.out_of_hours_activations_report_workbook_id[local.environment]) = {
      display_name       = "Out of Hours Activations Report"
      template_file_path = "out_of_hours_activations_report.json.tmpl"
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
  display_name        = local.environment == "live" ? each.value.display_name : "${each.value.display_name} (${local.environment})"
  data_json           = templatefile("${path.module}/dashboard_templates/${each.value.template_file_path}", each.value.variables)
  tags                = local.tags
}
