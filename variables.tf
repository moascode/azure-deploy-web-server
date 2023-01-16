variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  type = string
  default = "udacity-web-server"
}

variable "subscription_id" {
  description = "Subscription ID of azure account"
  type = string
  default = "${env.ARM_SUBSCRIPTION_ID}"
}

variable "client_id" {
  description = "App ID of azure account"
  type = string
  default = "${env.ARM_CLIENT_ID}"
}

variable "client_secret" {
  description = "Password of azure account"
  type = string
  default = "${env.ARM_CLIENT_SECRET}"
}

variable "tenant_id" {
  description = "Tenant ID of azure account"
  type = string
  default = "${env.ARM_TENANT_ID}"
}

variable "location" {
  description = "The Azure Region in which all resources should be created."
  type = string
  default = "Southeast Asia"
}

variable "vm_username" {
  description = "Username for Virtual machines"
  type = string
  default = "udacityvm"
}

variable "vm_password" {
  description = "Password for Virtual machines"
  type = string
  default = "${env.WEB_SERVER_VM_PASSWORD}"
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

variable "application_port" {
   description = "Port that is exposed to the external load balancer"
   default     = 80
}

variable "packer_resource_group_name" {
   description = "Name of the resource group in which the Packer image is created"
   default     = "udacity-packer-rg"
}

variable "packer_image_name" {
   description = "Name of the Packer image"
   default     = "ubuntu1804PackerImage"
}

variable "packer_gallery_name" {
   description = "Name of the Packer gallery"
   default     = ""
}

variable "ssh_access_port" {
   description = "Port that is used to access VMs"
   default     = "22"
}
