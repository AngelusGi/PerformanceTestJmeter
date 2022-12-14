terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.26.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "0.3.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azuredevops" {
  org_service_url       = var.AZ_DEVOPS_URL
  personal_access_token = var.AZ_DEVOPS_TOKEN
}
