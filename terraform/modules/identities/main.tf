resource "azurerm_user_assigned_identity" "platform" {
  name                = var.platform_identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "kubelet_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = var.kubelet_identity_object_id
}

resource "azurerm_role_assignment" "platform_key_vault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.platform.principal_id
}

# DNS Zone Contributor for cert-manager Workload Identity (Topic 06).
resource "azurerm_role_assignment" "platform_dns_zone_contributor" {
  scope                = var.dns_zone_id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.platform.principal_id
}
