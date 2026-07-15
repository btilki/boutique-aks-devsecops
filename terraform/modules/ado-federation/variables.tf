variable "resource_group_name" {
  description = "Resource group for the pipeline user-assigned identity."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "identity_name" {
  description = "User-assigned managed identity for ADO pipelines."
  type        = string
  default     = "uami-ado-pipeline"
}

variable "ado_organization_id" {
  description = "Azure DevOps organization GUID (for OIDC issuer URL)."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.ado_organization_id))
    error_message = "ado_organization_id must be a GUID (Azure DevOps organization ID)."
  }
}

variable "ado_organization_name" {
  description = "Azure DevOps organization name (used in federation subject)."
  type        = string
}

variable "ado_project_name" {
  description = "Azure DevOps project name (used in federation subject)."
  type        = string
}

variable "service_connection_name" {
  description = "Azure Resource Manager service connection name in ADO."
  type        = string
  default     = "azure-boutique-oidc"
}

variable "federation_subject" {
  description = "Federated credential subject from ADO service connection (Subject identifier field). Required for Microsoft Entra issuer — copy from ADO after creating SC draft; overrides legacy sc:// subject."
  type        = string
  default     = null
}

variable "federated_credential_name" {
  description = "Name of the federated identity credential resource."
  type        = string
  default     = "ado-oidc-federation"
}

variable "acr_id" {
  description = "ACR ARM ID for AcrPush role assignment."
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ARM ID for Secrets User role assignment."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID scoped for the service connection."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the identity."
  type        = map(string)
  default     = {}
}
