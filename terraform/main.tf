# ═══════════════════════════════════════════════════════
# main.tf — all Azure resources for the Employee
#           Management System project
#
# This file replaces ALL of these manual az commands:
#   az group create ...
#   az acr create ...
#   az aks create ...
#   az keyvault create ...
#   az keyvault secret set ... (x2)
#
# Resources are defined in dependency order — Terraform
# resolves the actual creation order automatically by
# reading the references between resources. You don't
# need to worry about "create RG before ACR" —
# Terraform figures that out from the references.
# ═══════════════════════════════════════════════════════


# ── 1. Resource Group ────────────────────────────────
# The container for everything. Deleting this deletes
# ALL resources inside it — one command to clean up.
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}


# ── 2. Azure Container Registry (ACR) ────────────────
# Private Docker registry. AKS pulls images from here
# using Managed Identity — no imagePullSecrets needed.
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
  # admin_enabled=false is more secure — forces use of
  # Azure AD identity (Managed Identity, Service Principal)
  # rather than a static username/password for the registry
  tags = var.tags
}


# ── 3. AKS Cluster ───────────────────────────────────
# Managed Kubernetes — Microsoft handles the control plane.
# We only pay for and manage the worker node VM.
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "employee-aks"
  tags                = var.tags

  # ── OIDC + Workload Identity ─────────────────────────
  # Enabled by default on newer AKS versions.
  # Cannot be disabled once on — must match existing state.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # ── Default node pool (worker nodes) ───────────────
  default_node_pool {
    name       = "default"
    node_count = var.aks_node_count
    vm_size    = var.aks_node_vm_size
    # os_disk_size_gb defaults to 128GB — fine for learning
  }

  # ── Managed Identity ────────────────────────────────
  # Replaces --enable-managed-identity flag in az aks create.
  # SystemAssigned = Azure creates and manages the identity
  # automatically. This identity is what allows AKS to pull
  # from ACR without any credentials in YAML files.
  identity {
    type = "SystemAssigned"
  }

  # ── Network profile ─────────────────────────────────
  # kubenet = simpler networking model, fine for learning.
  # In production you'd use Azure CNI for advanced features.
  network_profile {
    network_plugin = "kubenet"
    dns_service_ip = "10.0.0.10"
    service_cidr   = "10.0.0.0/16"
  }
}


# ── 4. ACR Pull permission for AKS ───────────────────
# This is what --attach-acr did in the az aks create command.
# Without this, AKS pods can't pull images from ACR.
# AcrPull = read-only access to pull images (not push).
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
  # kubelet_identity is the Managed Identity that runs on
  # each worker node and pulls images on behalf of pods.
  # We're granting IT (not the cluster identity) AcrPull
  # on the ACR resource specifically.
}


# ── 5. Key Vault ─────────────────────────────────────
# Secrets manager. MySQL passwords live here, not in YAML.
resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = var.tags

  # RBAC-based access control (the new model).
  # Replaces the old Access Policy model.
  # Permission to read/write secrets is granted via
  # role assignments (see resources below), not vault policies.
  enable_rbac_authorization = true
}


# ── 6. Current user/SP identity ──────────────────────
# "data" sources READ existing information from Azure
# rather than creating something new.
# We need the current user's object_id to grant them
# permission to write secrets to the Key Vault.
data "azurerm_client_config" "current" {}


# ── 7. Grant current user Key Vault Secrets Officer ──
# Even the creator of a vault needs explicit permission
# to write secrets (real bug hit during manual setup).
resource "azurerm_role_assignment" "kv_current_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
  # Key Vault Secrets Officer = read + write + delete
  # This is for YOUR account (the one running terraform apply)
  # so you can manage secrets in this vault
}


# ── 8. Store MySQL root password in Key Vault ────────
# These replace the two "az keyvault secret set" commands.
# depends_on ensures the role assignment above is complete
# before trying to write secrets (avoids race condition).
resource "azurerm_key_vault_secret" "mysql_root_password" {
  name         = "mysql-root-password"
  value        = var.mysql_root_password
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.kv_current_user]
  # Without depends_on, Terraform might try to create the
  # secret before your role assignment has propagated,
  # causing the same "Forbidden" error hit during manual setup
}

resource "azurerm_key_vault_secret" "mysql_app_password" {
  name         = "mysql-app-password"
  value        = var.mysql_app_password
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.kv_current_user]
}


# ── 9. Static Public IP ──────────────────────────────
# Replaces the az network public-ip create command.
# Lives in the AKS node resource group so AKS can use it.
resource "azurerm_public_ip" "static_ip" {
  name                = "employee-static-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
  # node_resource_group is the MC_* resource group AKS creates
  # automatically — e.g. MC_employee-rg_employee-aks_eastus
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags

  depends_on = [azurerm_kubernetes_cluster.aks]
}
