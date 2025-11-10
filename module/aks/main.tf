# Resource Group
resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "aks" {
  name                = var.vnet_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Subnet for AKS
resource "azurerm_subnet" "aks" {
  name                 = var.aks_subnet_name
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = var.aks_subnet_address_prefix
}

# User Assigned Managed Identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.cluster_name}-identity"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tags                = var.tags
}

# Role Assignment - Network Contributor for AKS Identity on VNet
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_virtual_network.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Private AKS Cluster with Spot VMs and Istio
resource "azurerm_kubernetes_cluster" "aks" {
  name                      = var.cluster_name
  location                  = azurerm_resource_group.aks.location
  resource_group_name       = azurerm_resource_group.aks.name
  dns_prefix                = var.dns_prefix
  kubernetes_version        = var.kubernetes_version
  private_cluster_enabled   = true
  sku_tier                  = "Standard"
  azure_policy_enabled      = false
  
  tags = var.tags

  # Default node pool with Spot VMs
  default_node_pool {
    name                   = var.node_pool_name
    node_count             = var.node_count
    vm_size                = var.node_vm_size
    os_disk_size_gb        = var.node_disk_size_gb
    vnet_subnet_id         = azurerm_subnet.aks.id
    max_pods               = var.max_pods
    type                   = "VirtualMachineScaleSets"
    enable_auto_scaling    = var.enable_auto_scaling
    min_count              = var.enable_auto_scaling ? var.min_count : null
    max_count              = var.enable_auto_scaling ? var.max_count : null
    
    # Enable Spot VMs
    priority               = "Spot"
    eviction_policy        = "Delete"
    spot_max_price         = -1  # Pay up to regular price
    
    upgrade_settings {
      max_surge = "10%"
    }
  }

  # Managed Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Network Profile
  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    load_balancer_sku  = "standard"
  }

  # Disable Azure Monitor (Log Analytics)
  oms_agent {
    log_analytics_workspace_id = null
    msi_auth_for_monitoring_enabled = false
  }

  # Enable RBAC
  role_based_access_control_enabled = true

  # Azure AD RBAC (optional - comment out if not needed)
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
  }

  # Service Mesh (Istio)
  service_mesh_profile {
    mode                             = "Istio"
    internal_ingress_gateway_enabled = true
    external_ingress_gateway_enabled = true
  }

  depends_on = [
    azurerm_role_assignment.aks_network_contributor
  ]
}
