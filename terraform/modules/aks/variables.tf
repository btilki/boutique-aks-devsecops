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
  default     = "Standard_D2s_v6"
}

variable "system_node_count" {
  description = "Fixed node count for the system pool."
  type        = number
  default     = 1
}

variable "user_node_vm_size" {
  description = "VM SKU for the user node pool."
  type        = string
  default     = "Standard_D4s_v6"
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
  description = "Optional Log Analytics workspace for Container Insights and AKS diagnostics. Null disables Azure Monitor integration (use in-cluster Loki per ADR-0012)."
  type        = string
  default     = null
}

variable "service_cidr" {
  description = "Kubernetes service CIDR — must not overlap the AKS node subnet (see docs/architecture/06-network-design.md)."
  type        = string
  default     = "10.1.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for kube-dns / CoreDNS service — must be within service_cidr."
  type        = string
  default     = "10.1.0.10"
}

variable "network_policy" {
  description = <<-EOT
    Kubernetes NetworkPolicy plugin for Azure CNI. Null = no enforcement (policies may exist but are inert).
    Set to \"azure\" for Azure Network Policy Manager when applying Topic 15 (Package 3).
    Changing this on an existing cluster often requires recreate — set at first apply when rebuilding.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.network_policy == null || contains(["azure", "calico"], var.network_policy)
    error_message = "network_policy must be null, \"azure\", or \"calico\"."
  }
}

variable "tags" {
  description = "Tags applied to the cluster."
  type        = map(string)
  default     = {}
}
