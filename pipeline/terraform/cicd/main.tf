terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2"
    }
  }

  backend "local" {
  }
}

provider "azuredevops" {
  org_service_url = var.azure_devops_org_service_url
}

provider "github" {
  owner = var.github_owner
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {
  subscription_id = data.azurerm_client_config.current.subscription_id
}
