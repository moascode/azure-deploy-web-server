provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name     = var.ARM_resource_group
}

resource "azurerm_virtual_network" "vn" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "vn_subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "publicip_lb" {
  name                = "${var.prefix}-pip-lb"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Static"
  tags                = var.tags
}

resource "azurerm_lb" "lb" {
  name                = "${var.prefix}-lb"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "${var.prefix}-lb-fip"
    public_ip_address_id = azurerm_public_ip.publicip_lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb_backend" {
  name                = "${var.prefix}-lb-backend"
  loadbalancer_id     = azurerm_lb.lb.id
}

resource "azurerm_lb_nat_rule" "lb_rule_http" {
  name                           = "${var.prefix}-lb-rule-http"
  resource_group_name            = data.azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.prefix}-lb-fip"
}

resource "azurerm_lb_probe" "lb_probe_http" {
  name                = "${var.prefix}-lb-probe-http"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  tags                = var.tags

  ip_configuration {
    name                          = "${var.prefix}-subnet"
    subnet_id                     = azurerm_subnet.vn_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_assoc" {
  network_interface_id    = azurerm_network_interface.nic.id
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend.id
  ip_configuration_name   = "${var.prefix}-subnet"
}

resource "azurerm_network_interface_nat_rule_association" "nic_lb_http" {
  network_interface_id  = azurerm_network_interface.nic.id
  nat_rule_id           = azurerm_lb_nat_rule.lb_rule_http.id
  ip_configuration_name = "${var.prefix}-subnet"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  #Add rule for Inbound Access
  security_rule {
    name                        = "AllowHTTP"
    priority                    = 102
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "80"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
  security_rule {
    name                        = "DenyAll"
    priority                    = 3000
    direction                   = "Inbound"
    access                      = "Deny"
    protocol                    = "*"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.vn_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

data "azurerm_image" "image" {
  name                = var.packer_image_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  size                            = var.vm_size

  network_interface_ids = [azurerm_network_interface.nic.id]
  source_image_id = data.azurerm_image.image.id

  os_disk {
    name                 = "${var.prefix}-osdisk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  computer_name  = "udacityvm"
  admin_username = var.vm_username
  admin_password = var.vm_password
  disable_password_authentication = false

  tags = var.tags
}

resource "azurerm_managed_disk" "managed_disk" {
  name                 = "${var.prefix}-disk"
  location             = data.azurerm_resource_group.rg.location
  resource_group_name  = data.azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "managed_disk_attach" {
  managed_disk_id    = azurerm_managed_disk.managed_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                =  10
  caching            = "ReadWrite"
}
