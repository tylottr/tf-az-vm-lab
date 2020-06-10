##########
# SSH Key
##########
resource "tls_private_key" "main_ssh" {
  algorithm = "RSA"
}

#################
# Resource Group
#################
resource "azurerm_resource_group" "main" {
  count = var.resource_group_name == "" ? 1 : 0

  name     = "${local.resource_prefix}-rg"
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name == "" ? azurerm_resource_group.main[0].name : var.resource_group_name
}

##########
# Network
##########
resource "azurerm_network_security_group" "main" {
  name                = "${local.resource_prefix}-nsg"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "ssh-allow"
    description                = "Allow SSH traffic to reach all inbound networks"
    direction                  = "Inbound"
    priority                   = "1000"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "22"
  }

  security_rule {
    name                       = "http-allow"
    description                = "Allow HTTP traffic to reach all inbound networks"
    direction                  = "Inbound"
    priority                   = "1100"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "80"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${local.resource_prefix}-vnet"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  address_space = [var.vnet_prefix]
}

resource "azurerm_subnet" "main" {
  name                = "default"
  resource_group_name = azurerm_virtual_network.main.resource_group_name

  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_prefix, 2, 0)]
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

##########
# Compute
##########
locals {
  vms = toset([for n in range(var.vm_count) : format("%s-%02d", local.resource_prefix, n + 1)])
}

resource "azurerm_public_ip" "main" {
  for_each = var.vm_public_access ? local.vms : toset([])

  name                = "${each.value}-pip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  for_each = local.vms

  name                = "${each.value}-nic"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.vm_public_access ? azurerm_public_ip.main[each.value].id : null
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  for_each = local.vms

  name                = each.value
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  size                  = var.vm_size
  network_interface_ids = [azurerm_network_interface.main[each.value].id]

  admin_username = local.vm_admin_username
  admin_ssh_key {
    username   = local.vm_admin_username
    public_key = tls_private_key.main_ssh.public_key_openssh
  }

  custom_data = var.vm_custom_data_file != "" ? base64encode(file(var.vm_custom_data_file)) : null

  source_image_reference {
    publisher = local.vm_os.publisher
    offer     = local.vm_os.offer
    sku       = local.vm_os.sku
    version   = "latest"
  }

  os_disk {
    caching              = "None"
    disk_size_gb         = var.vm_disk_size
    storage_account_type = var.vm_disk_type
  }

  identity {
    type = "SystemAssigned"
  }
}
