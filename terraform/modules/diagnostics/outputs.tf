output "workspace_id" {
  description = "Log Analytics workspace ARM ID."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_name" {
  description = "Log Analytics workspace name."
  value       = azurerm_log_analytics_workspace.this.name
}

output "primary_shared_key" {
  description = "Primary shared key (sensitive) — prefer Azure AD auth in agents where possible."
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}
