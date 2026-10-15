mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {
  mock_resource "azurerm_ssh_public_key" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sshkey-unit/providers/Microsoft.Compute/sshPublicKeys/sshkeyunit"
    }
  }
}



variables {
  enable_telemetry    = false
  location            = "northeurope"
  name                = "sshkeyunit"
  public_key          = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD1s5zUr/RqRbmFcLPSxfAtl2cSPNI8gUf82WoSUAa2VEiNIrK5aCge0mZrXjxa7rlEAPJmMNNc3TnLFPsxTnEsOP9DZCIRJqcQ0o+8wAb2GPvlzYuXuojuqhCi2Wqe5MuFiY+8EpzJctpQ/Gyu6mLORt7MScVv1ica2Fg3/K7O4D/C6VFsMWZL28NXVlvBF8Rx6cMe9Y6qzWjDLbx6apiutRKpzDdfZRnkKrFdAvaAqIFbhPnh990GVQBwmSIlxbHrPkcYQz1tKUysUoVx9EZtMoDqjfgEkMqOGBacBwDqrT+8ux0qvCIJNUKaKK/T520QyFpYlTg6DMHfChIsCyKB unit-test"
  resource_group_name = "rg-sshkey-unit"
  tags = {
    environment = "unit"
  }
}

run "default_resource_and_outputs" {
  command = apply

  assert {
    condition = (
      output.resource.name == var.name &&
      output.resource.location == var.location &&
      output.resource.public_key == var.public_key &&
      output.resource.resource_group_name == var.resource_group_name &&
      output.resource.tags == var.tags
    )
    error_message = "The SSH public key must retain the supplied properties and tags."
  }

  assert {
    condition     = output.resource_id == azurerm_ssh_public_key.this.id && output.resource.id == output.resource_id
    error_message = "Both outputs must retain the primary resource ID."
  }

  assert {
    condition     = length(azurerm_management_lock.this) == 0 && length(azurerm_role_assignment.this) == 0
    error_message = "Locks and role assignments must remain disabled by default."
  }
}

run "lock_and_role_assignments" {
  command = apply

  variables {
    lock = {
      kind = "ReadOnly"
    }
    role_assignments = {
      by_name = {
        principal_id                     = "11111111-1111-1111-1111-111111111111"
        role_definition_id_or_name       = "Reader"
        skip_service_principal_aad_check = true
      }
      by_id = {
        principal_id               = "22222222-2222-2222-2222-222222222222"
        role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
      }
    }
  }

  assert {
    condition = (
      azurerm_management_lock.this[0].name == "lock-${var.name}" &&
      azurerm_management_lock.this[0].lock_level == "ReadOnly" &&
      azurerm_management_lock.this[0].scope == output.resource_id
    )
    error_message = "The generated lock name, level and resource scope must remain unchanged."
  }

  assert {
    condition = (
      length(azurerm_role_assignment.this) == 2 &&
      azurerm_role_assignment.this["by_name"].role_definition_name == "Reader" &&
      azurerm_role_assignment.this["by_name"].principal_id == var.role_assignments["by_name"].principal_id &&
      azurerm_role_assignment.this["by_name"].skip_service_principal_aad_check &&
      azurerm_role_assignment.this["by_name"].scope == output.resource_id &&
      azurerm_role_assignment.this["by_id"].role_definition_id == var.role_assignments["by_id"].role_definition_id_or_name &&
      azurerm_role_assignment.this["by_id"].scope == output.resource_id
    )
    error_message = "Role assignments must retain their map keys, principal, role selection and SSH-key scope."
  }
}

run "explicit_lock_name" {
  command = apply

  variables {
    lock = {
      kind = "CanNotDelete"
      name = "custom-lock"
    }
  }

  assert {
    condition = (
      azurerm_management_lock.this[0].name == "custom-lock" &&
      azurerm_management_lock.this[0].lock_level == "CanNotDelete" &&
      azurerm_management_lock.this[0].scope == output.resource_id
    )
    error_message = "An explicit lock name and level must remain attached to the SSH public key."
  }
}

run "invalid_lock_kind" {
  command = plan

  variables {
    lock = {
      kind = "Invalid"
    }
  }

  expect_failures = [var.lock]
}
