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


