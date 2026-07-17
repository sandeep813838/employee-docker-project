# ═══════════════════════════════════════════════════════
# variables.tf — declares all input variables
#
# This is Terraform's equivalent of Helm's values.yaml —
# all configurable values live here with descriptions
# and defaults. Actual values go in terraform.tfvars.
#
# Why separate declaration from values:
#   variables.tf  → committed to Git (structure only)
#   terraform.tfvars → gitignored if it contains secrets
# ═══════════════════════════════════════════════════════

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "employee-rg"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
  # eastus chosen for VM SKU availability
  # on free trial accounts (D2s_v7 available here)
}

variable "acr_name" {
  description = "Azure Container Registry name (must be globally unique, 5-50 alphanumeric chars)"
  type        = string
  default     = "employeeacr"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "employee-aks"
}

variable "aks_node_count" {
  description = "Number of worker nodes in the AKS cluster"
  type        = number
  default     = 1
  # 1 node is enough for this project and keeps cost minimal
}

variable "aks_node_vm_size" {
  description = "VM size for AKS worker nodes"
  type        = string
  default     = "Standard_D2s_v7"
  # B2s not available on free trial accounts in eastus
  # D2s_v7 = 2 vCPU, 8GB RAM — better than B2s anyway
}

variable "key_vault_name" {
  description = "Azure Key Vault name (globally unique, 3-24 chars)"
  type        = string
  default     = "employee-kv"
}

variable "mysql_root_password" {
  description = "MySQL root password — stored in Key Vault, never in code"
  type        = string
  sensitive   = true
  # sensitive = true means Terraform masks this value
  # in all plan/apply output, same as Jenkins Secret Text
  # No default — MUST be provided via terraform.tfvars
  # or environment variable TF_VAR_mysql_root_password
}

variable "mysql_app_password" {
  description = "MySQL app user password — stored in Key Vault"
  type        = string
  sensitive   = true
  # No default — must be provided
}

variable "tags" {
  description = "Tags applied to all Azure resources"
  type        = map(string)
  default = {
    Project     = "employee-management"
    Environment = "learning"
    ManagedBy   = "terraform"
  }
  # Tags are Azure metadata — useful for cost tracking
  # and filtering resources. ManagedBy=terraform tells
  # anyone looking at the Azure portal that these
  # resources are managed by Terraform, not manual CLI.
}
