terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  enable_telemetry    = var.enable_telemetry # see variables.tf
  name                = "mytestkey"
  resource_group_name = azurerm_resource_group.this.name
  public_key          = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiRzNAH4gEPpHvd4Qmhtwt8PmxuBNAGyuCADJbD447kcq+zHdFqhIPUQArfJAy/f+KMHEWTMd8zW1wx/NDFM/LJ1Jq9rpEDJLnvv1knwKeQMM7wrpQ4sG/Hp7RW1OVNiqyxREcfrccLxyXknrQsqea53QkSUuXKDym+SwtYlguudL/VT1ITScsYl5f9D5IqOVDq2JIfs8W+4klVzpK1Ap5/EdXvSMVBgGtvlIZjqOZFbT9bMvPLr4IXgVPWd++/zCD3cTnBVr8edbBIj33JqwVc99tM0nFocXjr+H6BVJ6B0h3oPDHjenIIbAoSOSyruJ6HYYFM+p+syvRDADuRqKwwIDAQAB"
  tags = {
    key            = "avm-res-compute-publicsshkey"
    "hidden-title" = "Test SSH Key"
    integers       = 123
  }
}
