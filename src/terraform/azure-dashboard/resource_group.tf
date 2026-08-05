resource "azurerm_resource_group" "this" {
  location = "UK South"
  name     = local.resource_group_name
  tags     = local.tags
}
