variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  type = string
  default = "udacity-web-server"
}

variable "location" {
  description = "The Azure Region in which all resources should be created."
  type = string
  default = "East US"
}

variable "ARM_subscription_id" {
  description = "Subscription ID of azure account"
  type = string
  default = ""
}

variable "ARM_client_id" {
  description = "App ID of azure account"
  type = string
  default = ""
}

variable "ARM_client_secret" {
  description = "Password of azure account"
  type = string
  default = ""
}

variable "ARM_tenant_id" {
  description = "Tenant ID of azure account"
  type = string
  default = ""
}

variable "ARM_resource_group" {
  description = "Tenant ID of azure account"
  type = string
  default = ""
}

variable "vm_username" {
  description = "Username for Virtual machines"
  type = string
  default = "moascodevm"
}

variable "vm_password" {
  description = "Password for Virtual machines"
  type = string
  default = "Hellouvm2023"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type = string
  default = "Standard_D2s_v3"
}

variable "tags" {
   description = "Map of the tags to use for the resources that are deployed"
   type        = map(string)
   default = {
      project = "udacity-web-server"
   }
}

variable "packer_image_name" {
   description = "Name of the Packer image"
   default     = "ubuntu1804PackerImage"
}

variable "vm_count" {
   description = "Number of instances of VM"
   default = 2
}
