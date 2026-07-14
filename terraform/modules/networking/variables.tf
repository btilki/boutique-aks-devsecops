variable "resource_group_name" {
  description = "Resource group that hosts networking resources."
  type        = string
}

variable "location" {
  description = "Azure region for networking resources."
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
}

variable "aks_subnet_name" {
  description = "Subnet name for the AKS node pool."
  type        = string
  default     = "aks-subnet"
}

variable "aks_subnet_prefixes" {
  description = "Address prefixes for the AKS subnet."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to networking resources."
  type        = map(string)
  default     = {}
}
