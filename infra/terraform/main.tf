# ── Resource Group ─────────────────────────────────────────────
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_prefix}-dev"
  location = var.location
}

# ── Azure Container Registry ───────────────────────────────────
resource "azurerm_container_registry" "acr" {
  name                = "${var.project_prefix}acr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false # false is correct for AKS role-based pull
}

# ── Azure Log Analytics Workspace ──────────────────────────────
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.project_prefix}-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# ── Azure Kubernetes Service ───────────────────────────────────
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.project_prefix}-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-${var.project_prefix}-dev"
  default_node_pool {
    name       = "system"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }
  identity {
    type = "SystemAssigned"
  }
  monitor_metrics {} # BUG-1 FIX: replaces deprecated oms_agent block
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }
}

# ── Allow AKS to pull from ACR ─────────────────────────────────
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}