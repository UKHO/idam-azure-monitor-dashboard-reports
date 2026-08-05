locals {
  asssigned_identity_name            = "${local.service_name}-identity"
  federated_identity_credential_name = "${local.service_name}-federated-identity-credential"
  azdo_service_endpoint_name         = "${local.service_name}-write-sc"
}

resource "azurerm_user_assigned_identity" "this" {
  name = local.asssigned_identity_name

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_federated_identity_credential" "this" {
  name                      = local.federated_identity_credential_name
  user_assigned_identity_id = azurerm_user_assigned_identity.this.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azuredevops_serviceendpoint_azurerm.this.workload_identity_federation_issuer
  subject                   = azuredevops_serviceendpoint_azurerm.this.workload_identity_federation_subject
}

resource "azurerm_role_assignment" "this" {
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.this.id
}

resource "azuredevops_serviceendpoint_azurerm" "this" {
  project_id                             = data.azuredevops_project.this.id
  service_endpoint_name                  = local.azdo_service_endpoint_name
  description                            = "Service connection with write access to ${local.service_name}"
  azurerm_spn_tenantid                   = data.azurerm_client_config.current.tenant_id
  azurerm_subscription_id                = data.azurerm_client_config.current.subscription_id
  azurerm_subscription_name              = data.azurerm_subscription.current.display_name
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"

  credentials {
    serviceprincipalid = azurerm_user_assigned_identity.this.client_id
  }
}

resource "azuredevops_check_approval" "azurerm_sc" {
  project_id           = data.azuredevops_project.this.id
  target_resource_id   = azuredevops_serviceendpoint_azurerm.this.id
  target_resource_type = "endpoint"

  approvers = [
    data.azuredevops_group.build_admins.id,
    data.azuredevops_group.release_admins.id
  ]

  instructions               = "Please review and approve the service connection for ${local.service_name}."
  minimum_required_approvers = 1
  requester_can_approve      = false
  timeout                    = local.check_approval_timeout
}

