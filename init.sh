#!/bin/bash

echo "Setting environment variables for Terraform..."
# read -p "Client ID: " client_id
# read -p "Client Secret: " client_secret
# read -p "Subscription ID: " subscription_id
# read -p "Tenant ID: " tenant_id
# read -p "Resource Group: " resource_group

client_id=3275bdfd-ce52-4818-b3be-78824da9e704
client_secret=bJ48Q~Fb65yccdPi_bazzHnmjxnufb5W2~tkldu7
subscription_id=246c6ed1-ec54-4be8-81fc-1e5c45aa22d7
tenant_id=fc210d6e-088d-4914-b0c1-0044aad0cf25
resource_group="rg-udacity-webserver"

export TF_VAR_ARM_client_id=$client_id
export TF_VAR_ARM_client_secret=$client_secret
export TF_VAR_ARM_subscription_id=$subscription_id
export TF_VAR_ARM_tenant_id=$tenant_id
export TF_VAR_ARM_resource_group=$resource_group
echo "Done!"