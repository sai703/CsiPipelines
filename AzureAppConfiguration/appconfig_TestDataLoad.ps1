
$subscriptionId = "ec864827-a91d-4a4b-bdec-b367150f43fa"
$resourceGroupName = 'azurekeyvaultsecretRG'

# Connect to your Azure account
Connect-AzAccount -Subscription $subscriptionId -UseDeviceAuthentication

# Specify the name of the Azure App Configuration store
$appConfigName = "api-test-csi"

# Generate and store 1000 app config items
for ($i = 1; $i -le 1000; $i++) {
    $key = "testKey$i"
    $value = "testValue$i"

    # Set the app config value
    az appconfig kv set --name $appConfigName  --key $key --value $value --subscription $subscriptionId --yes -y
    Write-Host "Added: Key: $key, Value: $value"
}

Write-Host "Test data generation complete."
