output "id" {
  description = "AKS cluster ARM ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "fqdn" {
  description = "API server FQDN."
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity and ADO federation."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Kubelet managed identity object ID (AcrPull assignments)."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "kubelet_identity_client_id" {
  description = "Kubelet managed identity client ID."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].client_id
}

output "identity_principal_id" {
  description = "Cluster control plane managed identity principal ID."
  value       = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

output "node_resource_group" {
  description = "Auto-generated node resource group name."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}
