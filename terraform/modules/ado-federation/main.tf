data "azurerm_client_config" "current" {}

locals {
  subscription_id = coalesce(var.subscription_id, data.azurerm_client_config.current.subscription_id)
  tenant_id       = data.azurerm_client_config.current.tenant_id
  issuer          = "https://vstoken.dev.azure.com/${var.ado_organization_id}"
  subject         = "sc://${var.ado_organization_name}/${var.ado_project_name}/${var.service_connection_name}"
}

resource "azurerm_user_assigned_identity" "pipeline" {
  name                = var.identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "ado" {
  name                = var.federated_credential_name
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.pipeline.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = local.issuer
  subject             = local.subject
}

resource "azurerm_role_assignment" "pipeline_acr_push" {
  scope                = var.acr_id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.pipeline.principal_id
}

resource "azurerm_role_assignment" "pipeline_key_vault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.pipeline.principal_id
}
