# Data
data "azurerm_client_config" "main" {
}

resource "random_integer" "main" {
  min = 0
  max = 9999
}

resource "tls_private_key" "main_ssh" {
  algorithm = "RSA"
}

resource "local_file" "main_ssh" {
  filename          = ".terraform/.ssh/main"
  sensitive_content = tls_private_key.main_ssh.private_key_pem

  provisioner "local-exec" {
    on_failure = continue

    command = "chmod 500 .terraform/.ssh/main"
  }
}

# Resources
## Resource Group
resource "azurerm_resource_group" "main" {
  name = "${var.resource_prefix}-rg"

  location = var.location
  tags     = var.tags
}

## Networking
resource "azurerm_network_security_group" "main" {
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
    name                       = "rdp-allow"
    description                = "Allow RDP traffic to reach all inbound networks"
    direction                  = "Inbound"
    priority                   = "1100"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "3389"
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
  address_space       = [var.vnet_prefix]
}

resource "azurerm_subnet" "main" {
  name                      = "default"
  resource_group_name       = azurerm_virtual_network.main.resource_group_name
  virtual_network_name      = azurerm_virtual_network.main.name
  address_prefix            = cidrsubnet(azurerm_virtual_network.main.address_space[0], 2, 0)
  network_security_group_id = azurerm_network_security_group.main.id
}

## Compute
resource "azurerm_public_ip" "main" {
  count               = var.vm_public_access ? var.vm_count : 0
  name                = "${local.vm_name}${count.index + 1}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.tags
  allocation_method   = "Static"
  domain_name_label   = "${local.vm_name}${count.index + 1}"
}

resource "azurerm_network_interface" "main" {
  count               = var.vm_count
  name                = "${local.vm_name}${count.index + 1}-nic"
  tags                = var.tags
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name = "ipconfig"

    subnet_id = azurerm_subnet.main.id

    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.vm_public_access ? azurerm_public_ip.main[count.index].id : null
  }
}

resource "azurerm_virtual_machine" "main" {
  count                            = var.vm_count
  name                             = "${local.vm_name}${count.index + 1}"
  resource_group_name              = azurerm_resource_group.main.name
  location                         = azurerm_resource_group.main.location
  tags                             = var.tags
  vm_size                          = var.vm_size
  network_interface_ids            = [azurerm_network_interface.main[count.index].id]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "${local.vm_name}${count.index + 1}"
    admin_username = var.vm_username
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path = "/home/${var.vm_username}/.ssh/authorized_keys"

      key_data = tls_private_key.main_ssh.public_key_openssh
    }
  }

  storage_image_reference {
    publisher = local.vm_os.publisher
    offer     = local.vm_os.offer
    sku       = local.vm_os.sku
    version   = "latest"
  }

  storage_os_disk {
    name          = "${local.vm_name}${count.index + 1}-osdisk"
    caching       = "ReadWrite"
    create_option = "FromImage"
    disk_size_gb  = var.vm_disk_size
  }
}
