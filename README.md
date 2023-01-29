# Deploying a scalable IaaS web server in Azure

### Introduction
This project uses a Packer template and a Terraform template to deploy a customizable and scalable web server in Azure

### Getting Started
1. Clone this repository

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Usage
Use the following commands to setup the web server

* **`source init.sh`** to set environment variables for azure
* **`packer build ubuntu1804.json`** to create ubuntu server image
* **`terraform init`** to initialize terraform
* **`terraform validate`** to verify the configuration
* **`terraform plan -out plan.out`** to plan the deployment
* **`terraform apply plan.out`** to apply the deployment
* **`terraform destroy`** to delete all deployed resources

### Output
You should be able to view the html page by browsing **<public_ip_address>:80**

