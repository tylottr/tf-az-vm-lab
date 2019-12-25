# Global
variable "tenant_id" {
  description = "The tenant id of this deployment"
  type        = string
  default     = null
}

variable "subscription_id" {
  description = "The subcription id of this deployment"
  type        = string
  default     = null
}

variable "location" {
  description = "The location of this deployment"
  type        = string
  default     = "UK South"
}

variable "resource_prefix" {
  description = "A prefix for the name of the resource, used to generate the resource names"
  type        = string
  default     = "vmlab"
}

variable "tags" {
  description = "Tags given to the resources created by this template"
  type        = map(string)
  default     = {}
}

# Resource-specific
## VNET
variable "vnet_prefix" {
  description = "CIDR prefix for the VNet"
  type        = string
  default     = "10.100.0.0/24"
}

## Compute
variable "vm_public_access" {
  description = "Flag used to enable public access to spoke VMs"
  type        = bool
  default     = false
}

variable "vm_username" {
  description = "Username for the VMs"
  type        = string
  default     = "vmadmin"
}

variable "vm_os" {
  description = "VM Operating system (Linux - centos or ubuntu)"
  type        = string
  default     = "ubuntu"
}

variable "vm_size" {
  description = "VM Size for the VMs"
  type        = string
  default     = "Standard_B1s"
}

variable "vm_disk_type" {
  description = "VM disk type for the VMs"
  type        = string
  default     = "Standard_LRS"
}

variable "vm_disk_size" {
  description = "VM disk size for the VMs in GB (Minimum 30)"
  type        = number
  default     = 32
}

variable "vm_count" {
  description = "Number of VMs to deploy"
  type        = number
  default     = 1
}

# Locals
locals {
  tags = merge(
    var.tags,
    {
      deployedBy = "Terraform"
    }
  )
  
  vm_os_platforms = {
    ubuntu = {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
    }

    centos = {
      publisher = "OpenLogic"
      offer     = "CentOS"
      sku       = "7-CI"
    }
  }

  vm_os = {
    publisher = lookup(local.vm_os_platforms, lower(var.vm_os), local.vm_os_platforms.ubuntu).publisher
    offer     = lookup(local.vm_os_platforms, lower(var.vm_os), local.vm_os_platforms.ubuntu).offer
    sku       = lookup(local.vm_os_platforms, lower(var.vm_os), local.vm_os_platforms.ubuntu).sku
  }
}