#Azure Resource Manager (ARM) provider to create, update, and manage resources in Azure
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.41.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.ARM_subscription_id
  client_id       = var.ARM_client_id
  client_secret   = var.ARM_client_secret
  tenant_id       = var.ARM_tenant_id
}

#Use existing resource group to organize and manage resources
data "azurerm_resource_group" "rg" {
  name     = var.ARM_resource_group
}

#Create a virtual network to allow resources within the network to communicate with each other and with the internet
resource "azurerm_virtual_network" "vn" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = var.tags
}

#Create a subnet to isolate network for network security or access control purposes
resource "azurerm_subnet" "vn_subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = ["10.0.1.0/24"]
}

#Create virtual network interfaces to enable VMs to communicate over the network
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  tags                = var.tags

  ip_configuration {
    name                          = "${var.prefix}-subnet-${count.index}"
    subnet_id                     = azurerm_subnet.vn_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Add network security rules
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = var.tags

  #Rule for Inbound Access
  security_rule {
    name                       = "AllowAcessFromSubnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "*"
  }
  security_rule {
    name                        = "AllowHTTP"
    priority                    = 101
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "80"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
  security_rule {
    name                       = "DenyAcessFromInternet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "Internet"
    destination_port_range     = "*"
    destination_address_prefix = "*"
  }
}

#Apply network security rules to the subnet
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.vn_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#Apply network security rules to the network interfaces
resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  count                     = var.vm_count
  network_interface_id      = element(azurerm_network_interface.nic.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#Create a public IP address to allow load balancer to be accessed over the internet
resource "azurerm_public_ip" "publicip_lb" {
  name                = "${var.prefix}-pip-lb"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Static"
  tags                = var.tags
}

#Create a load balancer to distribute incoming network traffic across multiple VMs
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

#Create a backend address pool for load balancer to forward traffic to vm network interfaces
resource "azurerm_lb_backend_address_pool" "lb_backend" {
  name                = "${var.prefix}-lb-backend"
  loadbalancer_id     = azurerm_lb.lb.id
}

#Add load balancer rule to allow http traffic to be distributed across the pools
resource "azurerm_lb_nat_rule" "lb_rule_http" {
  count                          = var.vm_count
  name                           = "${var.prefix}-lb-rule-http-${count.index}"
  resource_group_name            = data.azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = "80${count.index}"
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.prefix}-lb-fip"
}

#Add load balancer health probe to monitor the health of the resources in the pool
resource "azurerm_lb_probe" "lb_probe_http" {
  name                = "${var.prefix}-lb-probe-http"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
}

#Link loadbalancer's backend address pool to network interfaces
resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_assoc" {
  count                   = var.vm_count
  network_interface_id    = element(azurerm_network_interface.nic.*.id, count.index)
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend.id
  ip_configuration_name   = "${var.prefix}-subnet-${count.index}"
}

#Link loadbalancer's NAT rule to network interfaces to allow interfaces use the rule for traffic
resource "azurerm_network_interface_nat_rule_association" "nic_lb_http" {
  count                 = var.vm_count
  network_interface_id  = element(azurerm_network_interface.nic.*.id, count.index)
  nat_rule_id           = element(azurerm_lb_nat_rule.lb_rule_http.*.id, count.index)
  ip_configuration_name = "${var.prefix}-subnet-${count.index}"
}

#Use existing image for the virtual machine
data "azurerm_image" "image" {
  name                = var.packer_image_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

#Create virtual machine availability sets
resource "azurerm_availability_set" "avail_set" {
    name                = "${var.prefix}-avail-set"
    resource_group_name = data.azurerm_resource_group.rg.name
    location            = data.azurerm_resource_group.rg.location
    tags = var.tags
}

#Create linux virtual machines
resource "azurerm_linux_virtual_machine" "vm" {
  count                           = var.vm_count
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  size                            = var.vm_size

  network_interface_ids = [element(azurerm_network_interface.nic.*.id, count.index)]
  source_image_id = data.azurerm_image.image.id
  availability_set_id = azurerm_availability_set.avail_set.id

  os_disk {
    name                 = "${var.prefix}-osdisk-${count.index}"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  computer_name  = "udacityvm"
  admin_username = var.vm_username
  admin_password = var.vm_password
  disable_password_authentication = false

  tags = var.tags
}

#Create managed disks for virtual machines
resource "azurerm_managed_disk" "managed_disk" {
  count                = var.vm_count
  name                 = "${var.prefix}-disk-${count.index}"
  location             = data.azurerm_resource_group.rg.location
  resource_group_name  = data.azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1
  tags                 = var.tags
}

#Attach disks to virtual machines
resource "azurerm_virtual_machine_data_disk_attachment" "managed_disk_attach" {
  count              = var.vm_count
  managed_disk_id    = azurerm_managed_disk.managed_disk.*.id[count.index]
  virtual_machine_id = azurerm_linux_virtual_machine.vm.*.id[count.index]
  lun                = count.index + 10
  caching            = "ReadWrite"
}


