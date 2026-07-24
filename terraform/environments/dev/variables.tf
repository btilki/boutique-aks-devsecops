variable "location" {
  description = "Azure region for all platform resources."
  type        = string
  default     = "germanywestcentral"
}

variable "resource_group_name" {
  description = "Platform resource group name."
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name."
  type        = string
  default     = "vnet-boutique-dev-gwc"
}

variable "vnet_address_space" {
  description = "VNet CIDR — see docs/architecture/06-network-design.md."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_name" {
  description = "Subnet for AKS nodes (used in Topic 03)."
  type        = string
  default     = "aks-subnet"
}

variable "aks_subnet_prefixes" {
  description = "AKS subnet CIDR."
  type        = list(string)
  default     = ["10.0.0.0/20"]
}

variable "dns_zone_name" {
  description = "Public DNS zone hosted in Azure DNS."
  type        = string
  default     = "biroltilki.art"
}

variable "tags" {
  description = "Common tags for platform resources."
  type        = map(string)
  default = {
    project     = "boutique-aks-devsecops"
    environment = "platform"
    managed_by  = "terraform"
  }
}

# --- Topic 03: AKS, ACR, Key Vault ---

variable "acr_name" {
  description = "Globally unique ACR name (alphanumeric only)."
  type        = string
}

variable "acr_sku" {
  description = "ACR SKU."
  type        = string
  default     = "Standard"
}

variable "key_vault_name" {
  description = "Key Vault name (unique within Azure)."
  type        = string
}

variable "kv_purge_protection_enabled" {
  description = "Key Vault purge protection (Topic 19). Default false for teardown-friendly pilot."
  type        = bool
  default     = false
}

variable "kv_network_acls_default_action" {
  description = "Key Vault network ACL default (Allow|Deny). Deny requires AKS subnet service endpoint (Topic 19)."
  type        = string
  default     = "Allow"
}

variable "kv_network_acls_ip_rules" {
  description = "Optional public IPs allowed when KV ACL is Deny (operators / break-glass)."
  type        = list(string)
  default     = []
}

variable "aks_cluster_name" {
  description = "AKS cluster name."
  type        = string
  default     = "aks-boutique-dev-gwc"
}

variable "aks_dns_prefix" {
  description = "DNS prefix for the Kubernetes API server."
  type        = string
  default     = "aksboutiquedevgwc"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version — see versions.yaml."
  type        = string
  default     = "1.34"
}

variable "aks_network_policy" {
  description = "AKS NetworkPolicy plugin (null | azure | calico). Set \"azure\" for Topic 15. Default null keeps Topics 00–13 behavior."
  type        = string
  default     = null
}

variable "system_node_vm_size" {
  description = "System node pool VM SKU."
  type        = string
  default     = "Standard_D2s_v6"
}

variable "system_node_count" {
  description = "System node pool size (fixed)."
  type        = number
  default     = 1
}

variable "user_node_vm_size" {
  description = "User node pool VM SKU."
  type        = string
  default     = "Standard_D4s_v6"
}

variable "user_node_count" {
  description = "Initial user node pool size."
  type        = number
  default     = 1
}

variable "user_node_min_count" {
  description = "User pool autoscale minimum."
  type        = number
  default     = 1
}

variable "user_node_max_count" {
  description = "User pool autoscale maximum."
  type        = number
  default     = 3
}

variable "platform_identity_name" {
  description = "User-assigned identity for platform workloads."
  type        = string
  default     = "uami-boutique-platform"
}

# --- Topic 04: ADO OIDC federation ---

variable "ado_pipeline_identity_name" {
  description = "User-assigned identity for ADO pipeline OIDC."
  type        = string
  default     = "uami-ado-pipeline"
}

variable "ado_organization_id" {
  description = "Azure DevOps organization GUID."
  type        = string
}

variable "ado_organization_name" {
  description = "Azure DevOps organization name."
  type        = string
}

variable "ado_project_name" {
  description = "Azure DevOps project name."
  type        = string
}

variable "ado_service_connection_name" {
  description = "ARM service connection name (must match federation subject)."
  type        = string
  default     = "azure-boutique-oidc"
}

variable "ado_federation_subject" {
  description = "Subject identifier from ADO service connection form (Entra issuer). Copy after SC draft; see docs/setup/04-ado-oidc.md Step 4.4."
  type        = string
  default     = null
}
