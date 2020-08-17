#########
# Global
#########

variable "tenant_id" {
  description = "The tenant id of this deployment"
  type        = string
  default     = null

  validation {
    condition     = var.tenant_id == null || can(regex("\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}", var.tenant_id))
    error_message = "The tenant_id must to be a valid UUID."
  }
}

variable "subscription_id" {
  description = "The subscription id of this deployment"
  type        = string
  default     = null

  validation {
    condition     = var.subscription_id == null || can(regex("\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}", var.subscription_id))
    error_message = "The subscription_id must to be a valid UUID."
  }
}

variable "client_id" {
  description = "The client id of this deployment"
  type        = string
  default     = null

  validation {
    condition     = var.client_id == null || can(regex("\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}", var.client_id))
    error_message = "The client_id must to be a valid UUID."
  }
}

variable "client_secret" {
  description = "The client secret of this deployment"
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "The name of an existing resource group - this will override the creation of a new resource group"
  type        = string
  default     = null
}

variable "location" {
  description = "The location of this deployment"
  type        = string
  default     = "Central US"
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

#############
# Networking
#############

variable "vnet_prefix" {
  description = "CIDR prefix for the VNet"
  type        = string
  default     = "10.100.0.0/24"
}

##########
# Compute
##########

variable "vm_public_access" {
  description = "Flag used to enable public access to spoke VMs"
  type        = bool
  default     = false
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
  default     = 30
}

variable "vm_custom_data_file" {
  description = "Custom data file to be passed to the created VMs"
  type        = string
  default     = null
}

variable "vm_count" {
  description = "Number of VMs to deploy"
  type        = number
  default     = 1
}

#########
# Locals
#########

locals {
  resource_prefix = var.resource_prefix

  vm_admin_username = "vmadmin"

  vm_os_platforms = {
    "ubuntu" = {
      "publisher" = "Canonical"
      "offer"     = "UbuntuServer"
      "sku"       = "18.04-LTS"
    }

    "centos" = {
      "publisher" = "OpenLogic"
      "offer"     = "CentOS"
      "sku"       = "7-CI"
    }
  }

  vm_os = {
    publisher = lookup(local.vm_os_platforms, lower(var.vm_os), local.vm_os_platforms.ubuntu).publisher
    offer     = lookup(local.vm_os_platforms, lower(var.vm_os), local.vm_os_platforms.ubuntu).offer
    sku       = lookup(local.vm_os_platforms, lower(var.vm_os), local.vm_os_platforms.ubuntu).sku
  }
}
