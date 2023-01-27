# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
Use "source init.sh" to set environment variables for azure
Use "packer build ubuntu1804.json" to create ubuntu server image
use "terraform init" to initialize terraform
Use "terraform validate" to verify the configuration
Use "terraform plan -out plan.out" to plan the deployment
Use "terraform apply plan.out" to apply the deployment
Use "terraform destroy" to delete all resources

### Output
**Your words here**

