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