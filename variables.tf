# Global
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
  default     = "labadmin"
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

variable "vm_disk_size" {
  description = "VM disk size for the VMs in GB (Minimum 30)"
  type        = number
  default     = 30
}

variable "vm_count" {
  description = "Number of VMs to deploy (Deployed in a round-robin fashion across two subnets)"
  type        = number
  default     = 3
}

# Locals
locals {
  vm_name = "${var.resource_prefix}-vm"

  vm_os_platforms = {
    ubuntu = {
      publisher = "Canonical"
      offer = "UbuntuServer"
      sku = "18.04-LTS"
    }

    centos = {
      publisher = "OpenLogic"
      offer = "CentOS"
      sku = "7-CI"
    }
  }

  vm_os = {
    publisher = lookup(local.vm_os_platforms, lower(var.vm_os), local.vm_os_platforms.ubuntu).publisher
    offer = lookup(local.vm_os_platforms, lower(var.vm_os), local.vm_os_platforms.ubuntu).offer
    sku = lookup(local.vm_os_platforms, lower(var.vm_os), local.vm_os_platforms.ubuntu).sku
  }
}