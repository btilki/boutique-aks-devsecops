output "platform_identity_id" {
  description = "Platform user-assigned identity ARM ID."
  value       = azurerm_user_assigned_identity.platform.id
}

output "platform_identity_client_id" {
  description = "Platform identity client ID for Workload Identity federation."
  value       = azurerm_user_assigned_identity.platform.client_id
}

output "platform_identity_principal_id" {
  description = "Platform identity principal ID."
  value       = azurerm_user_assigned_identity.platform.principal_id
}
