provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags = var.tags
}

resource "azurerm_virtual_network" "vn" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = var.tags
}

resource "azurerm_subnet" "vn_subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = ["10.0.0.0/24"]
  tags = var.tags
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name


  #Add rule for Inbound Access
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.ssh_access_port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-assoc" {
  subnet_id                 = azurerm_subnet.vn_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface" "nic" {
  count               = var.instances_count
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags = var.tags

  ip_configuration {
    name                          = "${var.prefix}-subnet-${count.index}"
    subnet_id                     = azurerm_subnet.vn_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "publicip" {
  count = var.instances_count
  name = "${var.prefix}-pip-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  allocation_method = "Static"
  tags = var.tags
}

resource "azurerm_lb" "lb" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = var.tags

  frontend_ip_configuration {
    name                 = "${var.prefix}-lb-frontendip"
    public_ip_address_id = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb_backend_address_pool" {
  name                = "${var.prefix}-lb-backendip"
  loadbalancer_id     = azurerm_lb.lb.id
  tags = var.tags
}

resource "azurerm_lb_probe" "lb_probe" {
  name                = "${var.prefix}-lb-tcp-probe"
  protocol            = "Tcp"
  port                = var.application_port
  loadbalancer_id     = azurerm_lb.lb.id
  resource_group_name = azurerm_resource_group.rg.name
  tags = var.tags
}

resource "azurerm_lb_rule" "lb_rule_app" {
  name                           = "${var.prefix}-lb-app-rule"
  protocol                       = "Tcp"
  frontend_port                  = var.application_port
  backend_port                   = var.application_port
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.lb_backend_address_pool.id 
  probe_id                       = azurerm_lb_probe.lb_probe.id
  loadbalancer_id                = azurerm_lb.lb.id
  resource_group_name            = azurerm_resource_group.rg.name
  tags                           = var.tags
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_associate" {
  count                   = var.instances_count
  network_interface_id    = azurerm_network_interface.nic.*.id[count.index]
  ip_configuration_name   = azurerm_network_interface.nic.*.ip_configuration.0.name[count.index]
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_address_pool.id
  tags = var.tags
}

data "azurerm_shared_image" "example" {
  name                = var.packer_image_name
  gallery_name        = var.packer_gallery_name
  resource_group_name = var.packer_resource_group_name
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                           = var.instances_count
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.vm_size
  admin_username                  = var.vm_username
  admin_password                  = var.vm_password
  disable_password_authentication = false
  tags                            = var.tags

  network_interface_ids = [
    element(azurerm_network_interface.nic.*.id, count.index)
  ]

  source_image_id = data.azurerm_shared_image.image.id

  os_disk {
    name                 = "${var.prefix}-osdisk-${count.index}"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

resource "azurerm_managed_disk" "managed_disk" {
  count                = var.instances_count
  name                 = "${var.prefix}-disk-${count.index}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "managed_disk_attach" {
  count              = var.instances_count
  managed_disk_id    = azurerm_managed_disk.managed_disk.*.id[count.index]
  virtual_machine_id = azurerm_linux_virtual_machine.vm.*.id[count.index]
  lun                = count.index + 10
  caching            = "ReadWrite"
  tags                 = var.tags
}
