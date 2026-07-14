variable "cluster_name" {
  description = "AKS cluster name."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the API server FQDN."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group hosting the cluster."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for node pools (from networking module)."
  type        = string
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version."
  type        = string
}

variable "system_node_vm_size" {
  description = "VM SKU for the system node pool."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "system_node_count" {
  description = "Fixed node count for the system pool."
  type        = number
  default     = 1
}

variable "user_node_vm_size" {
  description = "VM SKU for the user node pool."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "user_node_count" {
  description = "Initial node count for the user pool."
  type        = number
  default     = 1
}

variable "user_node_min_count" {
  description = "Minimum nodes for user pool autoscaling."
  type        = number
  default     = 1
}

variable "user_node_max_count" {
  description = "Maximum nodes for user pool autoscaling."
  type        = number
  default     = 3
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace for Container Insights."
  type        = string
}

variable "tags" {
  description = "Tags applied to the cluster."
  type        = map(string)
  default     = {}
}
