output "vms" {
  description = "Information for the generated VMs"
  value = {
    resource_group_name = azurerm_resource_group.main.name
    vms                 = [for e in azurerm_public_ip.main : e.fqdn]
    shared_identity     = azurerm_user_assigned_identity.main.id
  }
}