output "identity_client_id" {
  description = "Pipeline UAMI client ID — use in ADO ARM service connection."
  value       = azurerm_user_assigned_identity.pipeline.client_id
}

output "identity_principal_id" {
  description = "Pipeline UAMI principal ID."
  value       = azurerm_user_assigned_identity.pipeline.principal_id
}

output "tenant_id" {
  description = "Entra tenant ID for the service connection."
  value       = local.tenant_id
}

output "subscription_id" {
  description = "Azure subscription ID for the service connection."
  value       = local.subscription_id
}

output "issuer" {
  description = "OIDC issuer URL configured on the federated credential."
  value       = local.issuer
}

output "subject" {
  description = "Federation subject — must match ADO service connection sc:// path."
  value       = local.subject
}

output "service_connection_name" {
  description = "Expected ADO service connection name."
  value       = var.service_connection_name
}

output "ado_organization_name" {
  description = "Azure DevOps organization name."
  value       = var.ado_organization_name
}

output "ado_project_name" {
  description = "Azure DevOps project name."
  value       = var.ado_project_name
}
