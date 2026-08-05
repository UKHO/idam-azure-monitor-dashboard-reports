locals {
  resource_group_name     = "${local.service_name}-rg"
  resource_group_location = "UK South"
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.resource_group_location
}

