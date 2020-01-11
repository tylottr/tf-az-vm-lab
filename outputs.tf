output "main_rg_name" {
  value = azurerm_resource_group.main.name
}

output "main_vm_fqdns" {
  value = [for endpoint in azurerm_public_ip.main : endpoint.fqdn]
}

output "vsts_vm_identity_id" {
  value = azurerm_user_assigned_identity.main.id
}

output "vsts_diag_sa_name" {
  value = azurerm_storage_account.main_diag.name
}