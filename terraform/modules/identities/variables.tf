variable "resource_group_name" {
  description = "Resource group for user-assigned identities."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "platform_identity_name" {
  description = "User-assigned identity for platform workloads (CSI, cert-manager)."
  type        = string
  default     = "uami-boutique-platform"
}

variable "kubelet_identity_object_id" {
  description = "AKS kubelet identity object ID for AcrPull."
  type        = string
}

variable "acr_id" {
  description = "ACR ARM ID for AcrPull role assignment."
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ARM ID for Secrets User assignment."
  type        = string
}

variable "dns_zone_id" {
  description = "Azure DNS zone ARM ID for cert-manager DNS-01 (Topic 06)."
  type        = string
}

variable "tags" {
  description = "Tags applied to identities."
  type        = map(string)
  default     = {}
}
