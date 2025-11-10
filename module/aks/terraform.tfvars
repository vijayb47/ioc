resource_group_name = "rg-aks-private"
location            = "eastus"
cluster_name        = "aks-private-cluster"
dns_prefix          = "aksprivate"
kubernetes_version  = "1.32"

# Networking
vnet_name                 = "vnet-aks"
vnet_address_space        = ["10.0.0.0/16"]
aks_subnet_name           = "snet-aks"
aks_subnet_address_prefix = ["10.0.1.0/24"]

# Kubernetes Network
network_plugin  = "azure"
network_policy  = "azure"
service_cidr    = "10.1.0.0/16"
dns_service_ip  = "10.1.0.10"

# Node Pool Configuration
node_pool_name     = "spotpool"
node_count         = 1
node_vm_size       = "Standard_D2s_v3"
node_disk_size_gb  = 30
max_pods           = 30

# Auto-scaling
enable_auto_scaling = true
min_count           = 1
max_count           = 3

# Tags
tags = {
  Environment = "Development"
  ManagedBy   = "Terraform"
  Project     = "AKS-Private"
}
