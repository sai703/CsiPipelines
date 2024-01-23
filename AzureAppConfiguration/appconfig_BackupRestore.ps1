# Define the parameters
param (
    [Parameter(Mandatory = $false)]
    [string]$subscriptionId,
    [string]$storageAccountName,
    [string]$storageContainerName,
    [string]$resourceGroupName,
    [string]$KeysToRestore ,
    [string]$zipFileName,
    [string]$appconfigName,
    [string]$AZURE_SP_CLIENT_SECRET,
    [string]$AZURE_SP_CLIENT_ID,
    [string]$TenantId,
    [string]$Action
)

# Get the current UTC date and time
$utcDateTime = [System.DateTime]::UtcNow

# Format the UTC date and time as desired (e.g., yyyy-MM-dd_HH-mm-ss)
$dateTimeString = $utcDateTime.ToString("yyyy-MM-dd_HH-mm-ss")
#$TenantId = '350118a2-b385-443c-a3d3-440dd3c3fde1'
$SecurePassword = ConvertTo-SecureString -String $AZURE_SP_CLIENT_SECRET -AsPlainText -Force


# az login --service-principal -u $AZURE_SP_CLIENT_ID -p $AZURE_SP_CLIENT_SECRET 
az login --service-principal --tenant $TenantId --username $AZURE_SP_CLIENT_ID --password $AZURE_SP_CLIENT_SECRET
az account set --subscription $subscriptionId

#az login --use-device-code
#az account set --subscription $subscriptionId

$appConfigs = az appconfig list --subscription $subscriptionId | ConvertFrom-Json

switch ($Action) {
    "BackupAppConfig" {
        # Add the code to back up the App Configs here
        Write-Host "Performing App Config backup..."
        function Clean-Filename {
            param (
                [string]$filename
            )
            
            # Define a regular expression pattern to match special characters
            $pattern = '[\\/:*?"<>|]'
            
            # Use the -replace operator to replace special characters with an empty string
            $cleanedFilename = $filename -replace $pattern, ''
            
            return $cleanedFilename
        }
        foreach ($appConfig in $appConfigs) {
            $appConfigName = $appConfig.name
            Write-Host "App Configuration: $appConfigName"

            $keysJson = az appconfig kv list --all --name $appConfigName --subscription $subscriptionId
            $keysArray = $keysJson | ConvertFrom-Json

            $tempDirectory = New-Item -ItemType Directory -Path "$env:TEMP\AppConfigs\$appConfigName" -Force

            if ($keysArray.Count -gt 0) {
                # Stats counters
                $keyCounter = 0
    
                foreach ($key in $keysArray) {
                    $fileName = $key.key
                    Write-Host "Key: $fileName"
                    $keyJsonString = $key | ConvertTo-Json -Depth 4
                    $cleanedFilename = Clean-Filename -filename $fileName
                    $backupFileName = Join-Path -Path $tempDirectory.FullName -ChildPath "$cleanedFilename.json" 
                    $keyJsonString | Out-File -FilePath $backupFileName
                    Write-Host "Saved JSON to: $backupFileName"
                    $keyCounter = $keyCounter + 1

                }
                
                $zipFileName = $appConfigName + "_" + "backup_$dateTimeString.zip"


                # Zip the app config backup files into a single archive
                $zipFilePath = Join-Path -Path "$env:TEMP\AppConfigs" -ChildPath $zipFileName
                Set-Location -Path $tempDirectory.FullName
                Compress-Archive -Path .\* -DestinationPath $zipFilePath -Force

                # Create the subfolder path
                $blobPath = "$subscriptionId/AppConfigs/$appConfigName/$zipFileName"
                $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AZURE_SP_CLIENT_ID, $SecurePassword
                Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential
                Set-AzContext -Subscription $subscriptionId
               
                # Upload the backup file to the storage account
                $storageContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context
                $sasToken = New-AzStorageBlobSASToken -Container $storageContainerName -Blob $blobPath -Permission w  -Context $storageContext
                az storage blob upload --account-name $storageAccountName --sas-token $sasToken --container-name $storageContainerName --type block --name $blobPath --file $zipFilePath

                Write-Output "`nEXPORTED from `"$appConfigName`" to `"$blobPath`":"
                Write-output "$keyCounter keys exported"
                $AllMessages += "$blobPath"
    
    
            }
            else {
                Write-Output "`nNO ACTION for $($appConfigName): `nThere are no App Configs to backup!"
            }
            Write-Output "##vso[task.setvariable variable=AllMessages]$blobPath"
        }
    }
    "RestoreAppConfig" {
        Write-Host "Performing App Configuration restoration..."
      
        # Ensure the temp directory exists
        $tempDirectory = New-Item -ItemType Directory -Path "$env:TEMP\AppConfigs" -Force
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName

        $storageAccountContext = $storageAccount.Context
        write-host $storageContainerName
        write-host $zipFileName
        write-host tempDirectory
        Get-AzStorageBlobContent -Container $storageContainerName -Blob $zipFileName -Destination $tempDirectory -Context $storageAccountContext -Force
        
        $destinationPath = Join-Path -Path $tempDirectory -ChildPath ""

        $zipFilePath = Join-Path -Path $tempDirectory.FullName -ChildPath $zipFileName
        Expand-Archive -Path $zipFilePath -DestinationPath $destinationPath -Force

        function ProcessJsonContent {
            param (
                [string]$jsonContent,
                [string]$appConfigName,
                [string]$subscriptionId
            )
            # Convert JSON content to a PowerShell object
            $jsonObject = $jsonContent | ConvertFrom-Json
            Write-Host $jsonObject

            if ($jsonObject.label) {
                $labelParam = $jsonObject.label
            }
            else {
                $labelParam = "(No label)"
            }

            if ($jsonObject.contentType) {
                $contentTypeParam = $jsonObject.contentType
            }
            else {
                $contentTypeParam = "(No Content Type)"
            }
            az account set -s $subscriptionId
            if ($contentTypeParam -eq 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8') {
                $jsonString = $jsonObject.value  # Get the JSON string from the 'value' property
                $jsonValue = ConvertFrom-Json $jsonString  # Convert the JSON string to a PowerShell object
                $secretIdentifier = $jsonValue.uri

                # Use the Azure CLI to set the Key Vault reference
                az appconfig kv set-keyvault -n $appConfigName --key $jsonObject.key --label $labelParam --secret-identifier $secretIdentifier --yes
                Write-Host "App Configuration Key: '$KeyNameToRestore' has been restored from Azure Storage account."
            }
            else {
                az appconfig kv set -n $appConfigName --key $jsonObject.key --value $jsonObject.value  --label $labelParam  --content-type $contentTypeParam  --yes
                Write-Host "App Configuration Key:  '$KeyNameToRestore' has been restored from Azure Storage account."
            }
        }

        if ($KeysToRestore -ne $null -and $KeysToRestore.Length -gt 0) {
            $keysArray = $KeysToRestore -split '#'
            Write-Host $keysArray
            foreach ($KeyNameToRestore in $keysArray) {
                $jsonFileName = "${KeyNameToRestore}.json"
                $jsonFilePath = "$destinationPath\$jsonFileName"
                $jsonContent = Get-Content -Raw -Path $jsonFilePath
                ProcessJsonContent -jsonContent $jsonContent -appConfigName $appConfigName -subscriptionId $subscriptionId
            }
        }
        else {
            $files = Get-ChildItem -Path $destinationPath -File -Filter "*.json"
            foreach ($KeyNameToRestore in $files) {
                $jsonContent = Get-Content -Raw -Path $KeyNameToRestore
                ProcessJsonContent -jsonContent $jsonContent -appConfigName $appConfigName -subscriptionId $subscriptionId
            }

        }
        Write-Host "RestoreAppConfig."
    }
    default {
        Write-Host "Invalid action parameter. Please specify 'BackupAppConfig' or 'RestoreAppConfig'."
    }
}