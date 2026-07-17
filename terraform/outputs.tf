# ═══════════════════════════════════════════════════════
# outputs.tf — values printed after terraform apply
#
# These are the equivalent of the values you noted down
# manually after each az command. Now they're printed
# automatically after every apply.
#
# You can also query them any time with:
#   terraform output
#   terraform output acr_login_server
# ═══════════════════════════════════════════════════════

output "resource_group_name" {
  description = "Resource group containing all project resources"
  value       = azurerm_resource_group.rg.name
}

output "acr_login_server" {
  description = "ACR login server URL — use this in values-aks.yaml image paths"
  value       = azurerm_container_registry.acr.login_server
  # e.g. employeeacr.azurecr.io
}

output "acr_name" {
  description = "ACR name — use with az acr login --name"
  value       = azurerm_container_registry.acr.name
}

output "aks_cluster_name" {
  description = "AKS cluster name — use with az aks get-credentials"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_get_credentials_command" {
  description = "Run this command to connect kubectl to your AKS cluster"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing"
  # Complete command printed directly — just copy and paste
}

output "key_vault_name" {
  description = "Key Vault name — use with az keyvault secret show"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.kv.vault_uri
}

output "static_public_ip" {
  description = "Static public IP for the AKS LoadBalancer — update Jenkinsfile-aks AKS_PUBLIC_IP with this value"
  value       = azurerm_public_ip.static_ip.ip_address
}

output "aks_node_resource_group" {
  description = "The MC_* resource group AKS creates for node infrastructure"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "next_steps" {
  description = "Commands to run after terraform apply"
  value       = <<-EOT
    ── Next steps after terraform apply ──────────────────
    1. Connect kubectl to AKS:
       az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name}

    2. Push images to ACR:
       az acr login --name ${azurerm_container_registry.acr.name}
       docker push ${azurerm_container_registry.acr.login_server}/employee-backend:1.0
       docker push ${azurerm_container_registry.acr.login_server}/employee-frontend:1.0

    3. Deploy with Helm:
       helm install employee-app helm/employee-chart -f helm/employee-chart/values-aks.yaml

    4. Update Jenkinsfile-aks:
       AKS_PUBLIC_IP = "${azurerm_public_ip.static_ip.ip_address}"
       ACR_LOGIN     = "${azurerm_container_registry.acr.login_server}"
  EOT
}
