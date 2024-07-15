output "resource" {
  description = "This is the full output for the resource."
  value       = azurerm_ssh_public_key.this
}

output "resource_id" {
  description = "This is the ID of the resource."
  value       = azurerm_ssh_public_key.this.id
}
