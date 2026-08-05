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
  }

  backend "azurerm" {
  }
}

provider "azuredevops" {
  org_service_url = var.azure_devops_org_service_url
}

provider "github" {
  owner = var.github_owner
}
