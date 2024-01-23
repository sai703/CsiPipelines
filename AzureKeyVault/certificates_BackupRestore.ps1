# Define the parameters
param (
    [Parameter(Mandatory = $true)]
    [string]$subscriptionId,
    [string]$storageAccountName,
    [string]$storageContainerName,
    [string]$resourceGroupName,
    [string]$CertsToRestore,
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

#Connect-AzAccount -Subscription $subscriptionId -UseDeviceAuthentication

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
    "BackupCerts" {
        # Add the code to back up the keys here
        Write-Host "Performing certificate backup..."
        # Your backup logic goes here
        foreach ($keyVault in $keyVaults) {
            $keyVaultName = $keyVault.VaultName
            #$keyVaultName = $vaultName
            $zipFileName = $keyVaultName + "_" + "Certificates" + "_" + "backup_$dateTimeString.zip"
        
            # Get the Certificates in the Key Vault
            $Certificates = Get-AzKeyVaultCertificate -VaultName $keyVaultName
        
            if ($Certificates.Count -gt 0) {
                # Create a temporary directory for storing the Certificates files
                $tempDirectory = New-Item -ItemType Directory -Path "$env:TEMP\Certificates\$keyVaultName" -Force
        
                # Stats counters
                $keyCounter = 0
            
                # Backup each Certificate to a separate file
                foreach ($Certificate in $Certificates) {
                    try {
                        $CertificateName = $Certificate.Name
                        $backupFileName = Join-Path -Path $tempDirectory.FullName -ChildPath "$CertificateName.bak"
            
                        # Backup the Certificate
                        Backup-AzKeyVaultCertificate -VaultName $keyVaultName -Name $CertificateName -OutputFile $backupFileName -Force
                        Write-Host "Certificate '$CertificateName' backed up to '$backupFileName'"
                    }
                    catch {
                        Write-Error "$($Certificate.Name) was not exported"
                    }
                    $keyCounter = $keyCounter + 1
                }
            
                # Zip the Certificate backup files into a single archive
                $zipFilePath = Join-Path -Path "$env:TEMP\Certificates" -ChildPath $zipFileName
                Set-Location -Path $tempDirectory.FullName
                Compress-Archive -Path .\* -DestinationPath $zipFilePath -Force
        
                # Create the subfolder path
                $blobPath = "$subscriptionId/KeyVault/Certificates/$zipFileName"
                
                # Upload the backup file to the storage account
                $storageContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context
                Set-AzStorageBlobContent -Container $storageContainerName -Blob $blobPath -File $zipFilePath -Context $storageContext -Force
            
                # Delete the temporary directory
                Set-Location -Path "$env:TEMP"
                Remove-Item -Path $tempDirectory.FullName -Recurse -Force
            
                Write-Output "`nEXPORTED from `"$keyVaultName`" to `"$blobPath`":"
                Write-output "$keyCounter Certificates exported"
                $AllMessages += "$blobPath"
            }
            else {
                Write-Output "`nNO ACTION for $($keyVaultName): `nThere are no Certificates to backup!"
            }
        }
        Write-Output "##vso[task.setvariable variable=AllMessages]$blobPath"

    }
    "RestoreCerts" {

        # Add the code to restore the keys here
        $tempDirectory = New-Item -ItemType Directory -Path $env:TEMP\CertificateBackup -Force

        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName 

        $storageAccountContext = $storageAccount.Context

        Get-AzStorageBlobContent -Container $storageContainerName -Blob $zipFileName -Destination $tempDirectory -Context $storageAccountContext -Force

        $destinationPath = Join-Path -Path $tempDirectory -ChildPath ""

        $zipFilePath = Join-Path -Path $tempDirectory.FullName -ChildPath $zipFileName
        Expand-Archive -Path $zipFilePath -DestinationPath $destinationPath -Force

        if ($CertsToRestore -ne $null -and $CertsToRestore.Length -gt 0) {
            $certsArray = $CertsToRestore -split '#'
            foreach ($CertNameToRestore in $certsArray) {
                $deletedCertificate = Get-AzKeyVaultCertificate -VaultName $vaultName -Name $CertNameToRestore -InRemovedState 
                if ($deletedCertificate) {
                    Undo-AzKeyVaultCertificateRemoval -VaultName $vaultName -Name $deletedCertificate.Name
                    Write-Host "Certificate '$CertNameToRestore' has been restored. from manage deleted certificates."
                }
                else {
                    # Restore from Azure Storage account
    
                    # Restore the Certificates to Azure Key Vault
                    $inputFile = $destinationPath + '\' + $CertNameToRestore + '.bak'
            
                    $restoreOptions = @{
                        VaultName = $vaultName
                        InputFile = $inputFile
                    }
                    Restore-AzKeyVaultCertificate @restoreOptions    
                    Write-Host "Managed Certificate '$CertNameToRestore' has been restored from Azure Storage account."
                }
            }
        }
       
        else {

            #Restore all certificates from backup folder
            $files = Get-ChildItem -Path $destinationPath -File -Filter "*.bak"
            foreach ($certificate in $files) {
                $inputFile = $destinationPath + '\' + $certificate.name 
                $restoreOptions = @{
                    VaultName = $vaultName
                    InputFile = $inputFile
                }
                Restore-AzKeyVaultCertificate @restoreOptions    
            }
        }
 
    }
    default {
        Write-Host "Invalid action parameter. Please specify 'BackupKeys' or 'RestoreKeys'."
    }
}

# Output Key Vault details

