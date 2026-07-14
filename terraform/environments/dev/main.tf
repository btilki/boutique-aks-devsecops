# Dev environment root module — single physical AKS platform (Topics 02–04).
# Topic 02: resource group, networking, DNS, Log Analytics.
# Topic 03: AKS, ACR, Key Vault, identities.
# Topic 04: ADO OIDC federation (see docs/setup/04-ado-oidc.md).

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "networking" {
  source = "../../modules/networking"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  vnet_name           = var.vnet_name
  vnet_address_space  = var.vnet_address_space
  aks_subnet_name     = var.aks_subnet_name
  aks_subnet_prefixes = var.aks_subnet_prefixes
  tags                = var.tags
}

module "dns" {
  source = "../../modules/dns"

  resource_group_name = module.resource_group.name
  zone_name           = var.dns_zone_name
  tags                = var.tags
}

module "diagnostics" {
  source = "../../modules/diagnostics"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  workspace_name      = var.log_analytics_workspace_name
  retention_in_days   = var.log_analytics_retention_days
  tags                = var.tags
}

module "acr" {
  source = "../../modules/acr"

  name                       = var.acr_name
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  sku                        = var.acr_sku
  log_analytics_workspace_id = module.diagnostics.workspace_id
  tags                       = var.tags
}

module "key_vault" {
  source = "../../modules/key-vault"

  name                       = var.key_vault_name
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  log_analytics_workspace_id = module.diagnostics.workspace_id
  tags                       = var.tags
}

module "aks" {
  source = "../../modules/aks"

  cluster_name               = var.aks_cluster_name
  dns_prefix                 = var.aks_dns_prefix
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  subnet_id                  = module.networking.aks_subnet_id
  kubernetes_version         = var.kubernetes_version
  system_node_vm_size        = var.system_node_vm_size
  system_node_count          = var.system_node_count
  user_node_vm_size          = var.user_node_vm_size
  user_node_count            = var.user_node_count
  user_node_min_count        = var.user_node_min_count
  user_node_max_count        = var.user_node_max_count
  log_analytics_workspace_id = module.diagnostics.workspace_id
  tags                       = var.tags
}

module "identities" {
  source = "../../modules/identities"

  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  platform_identity_name     = var.platform_identity_name
  kubelet_identity_object_id = module.aks.kubelet_identity_object_id
  acr_id                     = module.acr.id
  key_vault_id               = module.key_vault.id
  dns_zone_id                = module.dns.zone_id
  tags                       = var.tags

  depends_on = [module.aks, module.acr, module.key_vault, module.dns]
}

module "ado_federation" {
  source = "../../modules/ado-federation"

  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  identity_name           = var.ado_pipeline_identity_name
  ado_organization_id     = var.ado_organization_id
  ado_organization_name   = var.ado_organization_name
  ado_project_name        = var.ado_project_name
  service_connection_name = var.ado_service_connection_name
  acr_id                  = module.acr.id
  key_vault_id            = module.key_vault.id
  tags                    = var.tags

  depends_on = [module.acr, module.key_vault]
}
