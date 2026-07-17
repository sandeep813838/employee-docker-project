# ═══════════════════════════════════════════════════════
# terraform.tfvars — actual values for variables
#
# ⚠ THIS FILE IS GITIGNORED — never commit it.
# It contains sensitive values (passwords).
# Add "terraform/*.tfvars" to your .gitignore.
#
# This is the equivalent of passing --set mysql.rootPassword=
# at helm upgrade time — the real value stays outside Git.
# ═══════════════════════════════════════════════════════

resource_group_name = "employee-rg"
location            = "eastus"
acr_name            = "employeeacr"
aks_cluster_name    = "employee-aks"
aks_node_count      = 1
aks_node_vm_size    = "Standard_D2s_v7"
key_vault_name      = "employee-kv"

# Passwords — stored in Key Vault by Terraform
# These are the ONLY place these values appear
# outside of Key Vault itself
mysql_root_password = "password"
mysql_app_password  = "apppassword"
