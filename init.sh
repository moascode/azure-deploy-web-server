#!/bin/bash

echo "Setting environment variables for Terraform..."
read -p "Client ID: " client_id
read -p "Client Secret: " client_secret
read -p "Subscription ID: " subscription_id
read -p "Tenant ID: " tenant_id
read -p "Resource Group: " resource_group

export TF_VAR_ARM_client_id=$client_id
export TF_VAR_ARM_client_secret=$client_secret
export TF_VAR_ARM_subscription_id=$subscription_id
export TF_VAR_ARM_tenant_id=$tenant_id
export TF_VAR_ARM_resource_group=$resource_group
echo "Done!"