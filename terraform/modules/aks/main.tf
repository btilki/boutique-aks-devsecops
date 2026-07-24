data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_vm_size
    vnet_subnet_id               = var.subnet_id
    node_count                   = var.system_node_count
    type                         = "VirtualMachineScaleSets"
    only_critical_addons_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = var.network_policy
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  lifecycle {
    ignore_changes = [
      kubernetes_version,
      default_node_pool[0].upgrade_settings,
      # Subscription / Defender for Containers may attach a microsoft_defender
      # profile outside this module; ignore to avoid plan drift disabling it.
      microsoft_defender,
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_node_vm_size
  vnet_subnet_id        = var.subnet_id
  mode                  = "User"
  node_count            = var.user_node_count
  enable_auto_scaling   = true
  min_count             = var.user_node_min_count
  max_count             = var.user_node_max_count
  tags                  = var.tags

  lifecycle {
    ignore_changes = [
      # With enable_auto_scaling, Azure manages count between min/max.
      node_count,
      upgrade_settings,
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "aks-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
