# Deploy a scalable IaaS web server in Azure

## Introduction
This project uses a Packer template and a Terraform template to deploy a customizable and scalable web server in Azure

## Getting Started
1. Clone this repository
2. Information about directories and files 

        - azure-policy -> contains azure policy rule
        - packer-image -> contains packer template to create linux image
        - terraform-server -> contains terraform templates to create webserver
        - init.sh -> script that sets environment variables
        - run.sh -> script that contains all azure command to create a webserver


## Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install [Git Bash](https://git-scm.com/downloads)
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

## Quick server deployment
* Run the command in bash CLI to deploy the webserver

        source run.sh

* The script requires following inputs. You should provide the value once prompted.
    
    1. **Client ID:** \<Azure application id>
    2. **Client Secret:** \<Azure secret key>
    3. **Subscription ID:** \<Azure subscription id>
    4. **Tenant ID:** \<Azure tenant id>
    5. **Resource Group:** \<Resource group name>
    6. **Number of instances of VM:** \<Ex: 2>

* After successful run, you should see the following screen

    ![Deployment completed](misc/terraform-deployed.png)

* Use **\<Address>:\<FrontendPort>** to access the webserver

    ![Access web server](misc/acess-web-server.png)

## Manual setup
### Initialize environment variables
1. Use *init.sh* to set environment variables for azure authentication

        source init.sh

    ![Init](misc/init.png)

2. Login to Azure

        az login --service-principal -u $TF_VAR_ARM_client_id -p $TF_VAR_ARM_client_secret --tenant $TF_VAR_ARM_tenant_id

3. Set the subscription

        az account set --subscription $TF_VAR_ARM_subscription_id

4. Create resource group for server image and infrustructure resources

        az group create --name $TF_VAR_ARM_resource_group --location eastus

### Set azure policy
1. Create policy definition
    
        az policy definition create --name "tagging-policy-definition" --rules "azure-policy/tagging-policy-rule.json" --display-name "Deny creation of resources without tags" --description "This policy denies creation of a resources if that do not have tags" --subscription $TF_VAR_ARM_subscription_id --mode Indexed

2. Assign policy

        az policy assignment create --name "tagging-policy" --policy "tagging-policy-definition"

3. Verify policy

        az policy assignment list

    ![Policy assignment](misc/policy-assignment-list.png)

### Create server image using packer
1. Run following command to create image in azure

        packer build packer-image/server.json

    ![build](misc/packer-build-image.png)

### Create server infrastructure
1. Change dircetory to terraform-server and initialize terraform

        cd terraform-server
        terraform init

    ![init](misc/terraform-init.png)

2. Change *default* value of *vars.tf* file according to your requirement

    ![variable-tag](misc/variable-tag.png)

2. Plan infrastructure deployment and provide number of VM you want to create 

        terraform plan -out solution.plan

    ![vm](misc/vm-count.png)
    ![plan](misc/terraform-plan.png)

3. Deploy infrastructure

        terraform apply solution.plan

    ![apply](misc/terraform-apply.png)

4. Get the public address and port to access the webserver

        az network public-ip list -g $TF_VAR_ARM_resource_group -o table
        az network lb inbound-nat-rule list -g $TF_VAR_ARM_resource_group --lb-name "web-server-lb" -o table

    ![deployed-manual](misc/terraform-deployed-manual.png)

5. Access web server using **\<Address>:\<FrontendPort>**

    ![Access web server](misc/acess-web-server.png)

*Use "terraform destroy" command to destroy the infrastructure*


## Troubleshooting

1. Error "Refused to connect"

    * If you see this error, it may be that webserver is not started.

        <img src="misc/faq-site-cant-be-reached.png" alt="Refused to connect" style="width:50%">

    * Follow steps as below to start the webserver in the vm

            #!/bin/bash
            
            echo 'Hello, World!' > index.html
            nohup busybox httpd -f -p 80 &

        ![Refused to connect solution](misc/faq-site-cant-be-reached-solution.png)

