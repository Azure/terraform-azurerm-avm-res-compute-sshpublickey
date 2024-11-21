terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71.0"
    }
    modtm = {
      source  = "Azure/modtm"
      version = ">= 0.3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}
