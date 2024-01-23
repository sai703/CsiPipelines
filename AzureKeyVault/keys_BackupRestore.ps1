# Define the parameters
param (
    [Parameter(Mandatory = $false)]
    [string]$subscriptionId,
    [string]$storageAccountName,
    [string]$storageContainerName,
    [string]$resourceGroupName,
    [string]$KeysToRestore ,
    [string]$zipFileName,
    [string]$vaultName,
    [string]$AZURE_SP_CLIENT_SECRET,
    [string]$AZURE_SP_CLIENT_ID,
    [string]$TenantId,
    [string]$Action
)
# Get the current UTC date and time
$utcDateTime = [System.DateTime]::UtcNow
$forbiddenKeys = @() 
# Format the UTC date and time as desired (e.g., yyyy-MM-dd_HH-mm-ss)
$dateTimeString = $utcDateTime.ToString("yyyy-MM-dd_HH-mm-ss")
# Login to Azure
# Connect-AzAccount -Subscription $subscriptionId -UseDeviceAuthentication
$SecurePassword = ConvertTo-SecureString -String $AZURE_SP_CLIENT_SECRET -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AZURE_SP_CLIENT_ID, $SecurePassword
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential
Set-AzContext -Subscription $subscriptionId

#Forbidden error: Due to permission issues we are not iterating all key-vaults. 
$keyVaults = Get-AzKeyVault
#$keyVaults = $vaultName
switch ($Action) {
    "BackupKeys" {
        # Add the code to back up the keys here
        Write-Host "Performing key backup..."
        # Output Key Vault details
        foreach ($keyVault in $keyVaults) {
            $keyVaultName = $keyVault.VaultName
            #$keyVaultName = $vaultName

            $zipFileName = $keyVaultName + "_" + "Keys" + "_" + "backup_$dateTimeString.zip"

            # Get the keys in the Key Vault
            $keys = Get-AzKeyVaultKey -VaultName $keyVaultName
            $certificates = Get-AzKeyVaultCertificate -VaultName $keyVaultName
            $certificateNames = $certificates.Name 
            if ($keys.Count -gt 0) {
                # Create a temporary directory for storing the key files
                $tempDirectory = New-Item -ItemType Directory -Path "$env:TEMP\Keys\$keyVaultName" -Force
                $keysOnly = $keys | Where-Object { $_.Name -notin $certificateNames }
                # Stats counters
                $keyCounter = 0
    
                # Backup each key to a separate file
                foreach ($key in $keysOnly) {
                    try {
                        $keyName = $key.Name
                        $backupFileName = Join-Path -Path $tempDirectory.FullName -ChildPath "$keyName.bak"
    
                        # Backup the key
                        Backup-AzKeyVaultKey -VaultName $keyVaultName -Name $keyName -OutputFile $backupFileName
                        Write-Host "Key '$keyName' backed up to '$backupFileName'"
              
                    }
                    catch {
                        $errorMessage = $_.Exception.Message 
                        Write-Host "Error: $errorMessage" 
                        $forbiddenKeys += $keyVaultName
                    }
                    $keyCounter = $keyCounter + 1
                }
                $forbiddenKeys
    
                # Zip the key backup files into a single archive
                $zipFilePath = Join-Path -Path "$env:TEMP\Keys" -ChildPath $zipFileName
                Set-Location -Path $tempDirectory.FullName
                Compress-Archive -Path .\* -DestinationPath $zipFilePath -Force

                # Create the subfolder path
                $blobPath = "$subscriptionId/KeyVault/keys/$zipFileName"
        
                # Upload the backup file to the storage account
                $storageContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context
                $sasToken = New-AzStorageBlobSASToken -Container $storageContainerName -Blob $blobPath -Permission w  -Context $storageContext
                az storage blob upload --account-name $storageAccountName --sas-token $sasToken --container-name $storageContainerName --type block --name $blobPath --file $zipFilePath
               
                # Delete the temporary directory
                #Set-Location -Path "C:\"
                # Remove-Item -Path $tempDirectory.FullName -Recurse -Force
    
                Write-Output "`nEXPORTED from `"$keyVaultName`" to `"$blobPath`":"
                Write-output "$keyCounter keys exported"
                $AllMessages += "$blobPath"
            }
            else {
                Write-Output "`nNO ACTION for $($keyVaultName): `nThere are no Keys to backup!"
            }
            Write-Output "##vso[task.setvariable variable=AllMessages]$blobPath"
        }
    }
    "RestoreKeys" {
        # Add the code to restore the keys here
        Write-Host "Performing key restoration..."
        # Your restoration logic goes here
        # Download the blob to a local file

        $tempDirectory = New-Item -ItemType Directory -Path $env:TEMP\KeyBackup -Force

        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName

        $storageAccountContext = $storageAccount.Context
        write-host $storageContainerName
        write-host $zipFileName
        write-host tempDirectory
        Get-AzStorageBlobContent -Container $storageContainerName -Blob $zipFileName -Destination $tempDirectory -Context $storageAccountContext -Force
        
        $destinationPath = Join-Path -Path $tempDirectory -ChildPath ""

        $zipFilePath = Join-Path -Path $tempDirectory.FullName -ChildPath $zipFileName
        Expand-Archive -Path $zipFilePath -DestinationPath $destinationPath -Force

        if ($KeysToRestore -ne $null -and $KeysToRestore.Length -gt 0) {
            $keysArray = $KeysToRestore -split '#'
            foreach ($KeyNameToRestore in $keysArray) {
                write-host $KeyNameToRestore
                $deletedKey = Get-AzKeyVaultKey -VaultName $vaultName -Name $KeyNameToRestore -InRemovedState
                if ($deletedKey) {
                    Undo-AzKeyVaultKeyRemoval -VaultName $vaultName -Name $deletedKey.Name
                    Write-Host "Key '$KeyNameToRestore' has been restored from manage deleted keys."
                }
                else {
                    
                    $inputFile = $destinationPath + '\' + $KeyNameToRestore + '.bak'
                    write-host $inputFile
                    $restoreOptions = @{
                        VaultName = $vaultName
                        InputFile = $inputFile
                    }
                    Restore-AzKeyVaultKey @restoreOptions
                    Write-Host "Managed Key '$KeyNameToRestore' has been restored from Azure Storage account."
                }
            }
        }

        else {

            #Restore all keys from backup folder

            $files = Get-ChildItem -Path $destinationPath -File -Filter "*.bak"
            foreach ($key in $files) {

                $inputFile = $destinationPath + '\' + $key.Name 

                $restoreOptions = @{

                    VaultName = $vaultName

                    InputFile = $inputFile

                }

                Restore-AzKeyVaultKey @restoreOptions    

            }

        }
    }
    default {
        Write-Host "Invalid action parameter. Please specify 'BackupKeys' or 'RestoreKeys'."
    }
}

