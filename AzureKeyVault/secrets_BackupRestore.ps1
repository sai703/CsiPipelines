

param (

    [Parameter(Mandatory = $true)]

    [string]$subscriptionId,

    [string]$storageAccountName,

    [string]$storageContainerName,

    [string]$resourceGroupName,

    [string]$SecretsToRestore,

    [string]$zipFileName,

    [string]$vaultName, 
    [string]$AZURE_SP_CLIENT_SECRET,
    [string]$AZURE_SP_CLIENT_ID,
    [string]$TenantId,
    [string]$Action
)

 

# Get the current UTC date and time

$utcDateTime = [System.DateTime]::UtcNow

 

# Format the UTC date and time as desired (e.g., yyyy-MM-dd_HH-mm-ss)

$dateTimeString = $utcDateTime.ToString("yyyy-MM-dd_HH-mm-ss")

 

# Login to Azure

#Connect-AzAccount -Subscription $subscriptionId -UseDeviceAuthentication
$SecurePassword = ConvertTo-SecureString -String $AZURE_SP_CLIENT_SECRET -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AZURE_SP_CLIENT_ID, $SecurePassword
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential
Set-AzContext -Subscription $subscriptionId
 

$keyVaults = Get-AzKeyVault

 

#$keyVaults = Get-AzKeyVault -VaultName $vaultName

 

switch ($Action) {

    "BackupSecrets" {

        # Add the code to back up the keys here

        Write-Host "Performing secrets backup..."

        # Your backup logic goes here


        # Output Key Vault details

        foreach ($keyVault in $keyVaults) {

            $keyVaultName = $keyVault.VaultName

            #$keyVaultName = $vaultName

 

            # Fetch the secrets in the Key Vault

            $secrets = Get-AzKeyVaultSecret -VaultName $keyVaultName

            $certificates = Get-AzKeyVaultCertificate -VaultName $keyVaultName

            $certificateNames = $certificates.Name

 

            if ($secrets.Count -gt 0) {

                # Create a temporary directory for storing the secret files

                $tempDirectory = New-Item -ItemType Directory -Path "$env:TEMP\Secrets\$keyVaultName" -Force

                $secretsOnly = $secrets | Where-Object { $_.Name -notin $certificateNames }

                # Stats counters

                $secretCounter = 0

 

                # Backup each secret to a separate file

                foreach ($secret in $secretsOnly) {

                    try {

                        $secretName = $secret.Name

                        $backupFileName = Join-Path -Path $tempDirectory.FullName -ChildPath "$secretName.bak"

 

                        # Backup the secret

                        Backup-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -OutputFile $backupFileName -Force

                        Write-Host "Secret '$secretName' backed up to '$backupFileName'"

                    }

                    catch {

                        Write-Error "$($secret.Name) was not exported"

                    }

                    $secretCounter = $secretCounter + 1

                }

 

                # Zip the secret backup files into a single archive

                $zipFileName = $keyVaultName + "_" + "Secrets" + "_" + "backup_$dateTimeString.zip"

                $zipFilePath = Join-Path -Path "$env:TEMP\Secrets" -ChildPath $zipFileName

                Set-Location -Path $tempDirectory.FullName

                Compress-Archive -Path .\* -DestinationPath $zipFilePath -Force

 

                # Create the subfolder path

                $blobPath = "$subscriptionId/KeyVault/secrets/$zipFileName"

 

                # Upload the backup file to the storage account

                $storageContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context

                Set-AzStorageBlobContent -Container $storageContainerName -Blob $blobPath -File $zipFilePath -Context $storageContext -Force

 

                # Delete the temporary directory

                # Set-Location -Path "C:\"

                # Remove-Item -Path $tempDirectory.FullName -Recurse -Force

 

                Write-Output "`nEXPORTED from `"$keyVaultName`" to `"$blobPath`":"

                Write-Output "$secretCounter secrets exported"
                $AllMessages += "$blobPath"
            }

            else {

                Write-Output "`nNO ACTION for $($keyVaultName): `nThere are no secrets to backup!"

            }

        }

 

    }

    "RestoreSecrets" {

        # Add the code to restore the keys here

        Write-Host "Performing key restoration..."

        # Your restoration logic goes here

        # Download the blob to a local file

        $tempDirectory = New-Item -ItemType Directory -Path $env:TEMP\SecretBackup -Force

        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName

        $storageAccountContext = $storageAccount.Context

        Get-AzStorageBlobContent -Container $storageContainerName -Blob $zipFileName -Destination $tempDirectory -Context $storageAccountContext -Force
        $destinationPath = Join-Path -Path $tempDirectory -ChildPath ""

        $zipFilePath = Join-Path -Path $tempDirectory.FullName -ChildPath $zipFileName
        Expand-Archive -Path $zipFilePath -DestinationPath $destinationPath -Force

        if ($SecretsToRestore -ne $null -and $SecretsToRestore.Length -gt 0) {
            $secretsArray = $SecretsToRestore -split '#'
            foreach ($SecretNameToRestore in $secretsArray) {

                $deletedSecret = Get-AzKeyVaultSecret -VaultName $vaultName -Name $SecretNameToRestore -InRemovedState

                if ($deletedSecret) {
                    Undo-AzKeyVaultSecretRemoval -VaultName $vaultName -Name $deletedSecret.Name
                    Write-Host "Secret '$SecretNameToRestore' has been restored from managed deleted secrets."
                }

                else {

                    # Restore from Azure Storage account


                    # Restore the Secret to Azure Key Vault

                    $inputFile = $destinationPath + '\' + $SecretNameToRestore + '.bak'


                    $restoreOptions = @{

                        VaultName = $vaultName

                        InputFile = $inputFile

                    }

                    Restore-AzKeyVaultSecret @restoreOptions

                    Write-Host "Secret '$SecretNameToRestore' has been restored from Azure Storage account."

                }

            }

        }

        else {

            # Restore all secrets from backup folder

            $files = Get-ChildItem -Path $destinationPath -File -Filter "*.bak"


            foreach ($Secret in $files) {

                $inputFile = $destinationPath + '\' + $Secret.Name

                $restoreOptions = @{

                    VaultName = $vaultName

                    InputFile = $inputFile

                }

                Restore-AzKeyVaultSecret @restoreOptions

                Write-Host "All Secrets has been restored from Azure Storage account."

            }

        }

    }


    default {

        Write-Host "Invalid action parameter. Please specify 'BackupSecrets' or 'RestoreSecrets'."

    }

}
