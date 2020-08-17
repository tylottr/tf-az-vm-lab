#########
# Global
#########

output "resource_group_name" {
  description = "Resource group of the VMs"
  value       = data.azurerm_resource_group.main.name
}

###################
# Virtual Machines
###################

output "vm_ids" {
  description = "List of VM Resource IDs"
  value       = [for vm in azurerm_linux_virtual_machine.main : vm.id]
}

output "vm_names" {
  description = "List of VM names mapped to public IP"
  value       = { for vm in azurerm_linux_virtual_machine.main : vm.name => vm.public_ip_address }
}


output "vm_identity_principal_ids" {
  description = "List of VM Identity Principal IDs"
  value       = [for vm in azurerm_linux_virtual_machine.main : vm.identity[0].principal_id]
}

output "admin_username" {
  description = "Username of the VM Admin"
  value       = local.vm_admin_username
}

output "admin_private_key" {
  description = "Private key data for the vm admin"
  value       = tls_private_key.main_ssh.private_key_pem
  sensitive   = true
}
