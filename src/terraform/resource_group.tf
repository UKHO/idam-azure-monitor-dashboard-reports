resource "azurerm_resource_group" "this" {
  location = "uksouth"
  name     = local.resource_group_name
  tags     = local.tags
}
