#!/bin/bash

# Call init.sh to set env variables
source init.sh

# Check if azure credentials are set
if [ -z "$TF_VAR_ARM_subscription_id" ] || [ -z "$TF_VAR_ARM_client_id" ] || [ -z "$TF_VAR_ARM_client_secret" ] || [ -z "$TF_VAR_ARM_tenant_id" ]; then
    echo "One or more Azure credentials are not set"
    exit 1
fi

# Login to Azure
az login --service-principal -u $TF_VAR_ARM_client_id -p $TF_VAR_ARM_client_secret --tenant $TF_VAR_ARM_tenant_id

# Set the subscription
az account set --subscription $TF_VAR_ARM_subscription_id

echo "---------Creating resource group---------"
if [ $(az group exists --name $TF_VAR_ARM_resource_group) = "false" ]; then
    # Create resource group
    az group create --name $TF_VAR_ARM_resource_group --location eastus
    echo "Resource group $TF_VAR_ARM_resource_group created"
else
    echo "Resource group $TF_VAR_ARM_resource_group exists"
fi

echo "---------Creating policy definition---------"
az policy definition create --name "tagging-policy-definition" --rules "azure-policy/tagging-policy-rule.json" --display-name "Deny creation of resources without tags" --description "This policy denies creation of a resources if that do not have tags" --subscription $TF_VAR_ARM_subscription_id --mode Indexed

echo "---------Setting policy---------"
az policy assignment create --name "tagging-policy" --policy "tagging-policy-definition"

echo "---------Deleting existing packer image---------"
az image delete -g $TF_VAR_ARM_resource_group -n "ubuntu1804PackerImage"
echo "done!"

echo "---------Building packer image---------"
packer build packer-image/server.json

echo "---------Initializing terraform---------"
cd terraform-server
terraform init

echo "---------Destroying existing server---------"
terraform destroy

echo "---------Planning deployment---------"
terraform plan -out solution.plan

echo "---------Starting deployment---------"
terraform apply solution.plan

echo -e "\n---------Deployment done!---------"
cd ..

echo -e "\n---------Pulic IP address---------"
az network public-ip list -g $TF_VAR_ARM_resource_group -o table

echo -e "\n---------Inbound port---------"
az network lb inbound-nat-rule list -g $TF_VAR_ARM_resource_group --lb-name "web-server-lb" -o table

echo -e "\n=========Use <Address>:<FrontendPort> to access the web server========="