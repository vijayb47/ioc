

SUBSCRIPTION_ID=39bf52d9-15ac-4965-a079-bb717a9971b6

az login --use-device-code
az account set --subscription $SUBSCRIPTION_ID


# Create Service Principal
az ad sp create-for-rbac \
  --name "terraform-aks-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --sdk-auth

# Get the Service Principal App ID from the output above
APP_ID="a8df1a5c-f4b7-4d71-a6ab-e0519ab71bc3"

# Network Contributor (for VNet operations)
az role assignment create \
  --assignee $APP_ID \
  --role "Network Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# User Access Administrator (for role assignments)
az role assignment create \
  --assignee $APP_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"