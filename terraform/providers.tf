# ═══════════════════════════════════════════════════════
# providers.tf — tells Terraform which cloud to talk to
#
# "required_providers" pins the exact version of the
# Azure plugin (called a "provider") to download.
# Like package.json in Node or pom.xml in Maven —
# version pinning ensures reproducible builds.
#
# azurerm = Azure Resource Manager — the main Azure
# provider that manages VMs, AKS, ACR, Key Vault etc.
# ═══════════════════════════════════════════════════════

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
      # ~> 3.0 means "any 3.x version" — allows patch
      # updates (3.1, 3.2...) but not major version
      # changes (4.0) which could break the API
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
      # used to generate a unique suffix for ACR name
      # since ACR names must be globally unique in Azure
    }
  }
}

provider "azurerm" {
  features {
    # Key Vault specific: don't purge secrets on destroy
    # During learning, we want destroy to be clean but
    # not permanently delete secrets (soft-delete keeps
    # them recoverable for 90 days by default)
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}
