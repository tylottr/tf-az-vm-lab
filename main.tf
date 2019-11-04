# Data
data "azurerm_client_config" "current" {}

resource "random_integer" "entropy" {
  min = 0
  max = 99
}

resource "tls_private_key" "main" {
  algorithm = "RSA"
}

resource "local_file" "main_ssh_public" {
  filename          = ".terraform/.ssh/id_rsa.pub"
  sensitive_content = tls_private_key.main.public_key_openssh
}

resource "local_file" "main_ssh_private" {
  filename          = ".terraform/.ssh/id_rsa"
  sensitive_content = tls_private_key.main.private_key_pem
  file_permission   = "0500"
}

# Resources
## Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.resource_prefix}-rg"
  location = var.location
  tags     = var.tags
}

## Networking
resource "azurerm_network_security_group" "main_default" {
  name                = "${var.resource_prefix}-default-nsg"
  resource_group_name = azurerm_virtual_network.main.resource_group_name
  location            = azurerm_virtual_network.main.location
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
    priority                   = "1200"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "80"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_prefix}-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.tags

  address_space = [var.vnet_prefix]
}

resource "azurerm_subnet" "main" {
  name                = "default"
  resource_group_name = azurerm_virtual_network.main.resource_group_name

  virtual_network_name      = azurerm_virtual_network.main.name
  address_prefix            = cidrsubnet(var.vnet_prefix, 2, 0)

  lifecycle {
    ignore_changes = [network_security_group_id]
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main_default.id
}

## Compute
resource "azurerm_public_ip" "main" {
  count = var.vm_public_access ? var.vm_count : 0

  name                = "${var.resource_prefix}-vm${count.index + 1}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.tags

  allocation_method = "Dynamic"
  domain_name_label = "${var.resource_prefix}-vm${count.index + 1}"
}

resource "azurerm_network_interface" "main" {
  count = var.vm_count

  name                = "${var.resource_prefix}-vm${count.index + 1}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.vm_public_access ? azurerm_public_ip.main[count.index].id : null
  }
}

resource "azurerm_virtual_machine" "main" {
  count = var.vm_count

  name                = "${var.resource_prefix}-vm${count.index + 1}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.tags

  vm_size                          = var.vm_size
  network_interface_ids            = [azurerm_network_interface.main[count.index].id]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "${var.resource_prefix}-vm${count.index + 1}"
    admin_username = var.vm_username
    custom_data    = null
  }

  storage_image_reference {
    publisher = local.vm_os.publisher
    offer     = local.vm_os.offer
    sku       = local.vm_os.sku
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.resource_prefix}-vm${count.index + 1}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    disk_size_gb      = var.vm_disk_size
    managed_disk_type = var.vm_disk_type
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.vm_username}/.ssh/authorized_keys"
      key_data = tls_private_key.main.public_key_openssh
    }
  }

  identity {
    type = "SystemAssigned"
  }
}
