# Input variables for the one-time Terraform remote state bootstrap stack.
# Apply this stack locally (no remote backend) before environments/dev/.

variable "location" {
  description = "Azure region for the state storage account and resource group."
  type        = string
  default     = "germanywestcentral"
}

variable "state_resource_group_name" {
  description = "Resource group that hosts the Terraform state storage account."
  type        = string
}

variable "storage_account_name" {
  description = "Globally unique storage account name (3-24 lowercase letters and numbers only)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 characters, lowercase letters and numbers only."
  }
}

variable "container_name" {
  description = "Blob container that stores Terraform state files."
  type        = string
  default     = "tfstate"
}

variable "tags" {
  description = "Tags applied to bootstrap resources for cost and ownership tracking."
  type        = map(string)
  default = {
    project     = "boutique-aks-devsecops"
    environment = "shared"
    managed_by  = "terraform-bootstrap"
  }
}
