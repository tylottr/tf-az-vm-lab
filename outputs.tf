output "main_rg_name" {
  value = azurerm_resource_group.main.name
}

output "main_vm_fqdns" {
  value = azurerm_public_ip.main.*.fqdn
}