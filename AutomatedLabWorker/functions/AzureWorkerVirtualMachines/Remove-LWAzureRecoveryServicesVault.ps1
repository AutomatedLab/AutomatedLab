function Remove-LWAzureRecoveryServicesVault
{
    [CmdletBinding()]
    param
    (
        [int]
        $RetryCount = 0
    )

    $lab = Get-Lab -ErrorAction SilentlyContinue
    if (-not $lab) { return }

    $rsVault = Get-AzResource -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -ResourceType Microsoft.RecoveryServices/vaults -ErrorAction SilentlyContinue
    if (-not $rsVault) { return }

    if (-not (Get-Module -ListAvailable -Name Az.RecoveryServices | Where-Object Version -ge '5.3.0'))
    {
        try
        {
            Install-Module -Force -Name Az.RecoveryServices -Repository PSGallery -MinimumVersion 5.3.0 -ErrorAction Stop
        }
        catch
        {
            Write-ScreenInfo -Type Error -Message "Unable to install Az.RecoveryServices, 5.3.0+. Please delete your RecoveryServices Vault $($rsVault.Id) yourself."
            return
        }
    }

    Write-LogFunctionEntry
    Write-ScreenInfo -Message "Removing recovery services vault $($rsVault.Id) in $($rsVault.ResourceGroupName) so that the resource group can be deleted properly. This takes a while."
    $vaultToDelete = Get-AzRecoveryServicesVault -Name $rsVault.ResourceName -ResourceGroupName $rsVault.ResourceGroupName
    $null = Set-AzRecoveryServicesAsrVaultContext -Vault $vaultToDelete

    $null = Set-AzRecoveryServicesVaultProperty -Vault $vaultToDelete.ID -SoftDeleteFeatureState Disable #disable soft delete
    $containerSoftDelete = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $vaultToDelete.ID | Where-Object { $_.DeleteState -eq "ToBeDeleted" } #fetch backup items in soft delete state
    foreach ($softitem in $containerSoftDelete)
    {
        $null = Undo-AzRecoveryServicesBackupItemDeletion -Item $softitem -VaultId $vaultToDelete.ID -Force #undelete items in soft delete state
    }
    
    if ((Get-Command Set-AzRecoveryServicesVaultProperty).Parameters.ContainsKey('DisableHybridBackupSecurityFeature'))
    {
        $null = Set-AzRecoveryServicesVaultProperty -VaultId $vaultToDelete.ID -DisableHybridBackupSecurityFeature $true
    }

    #Fetch all protected items and servers
    # Collection of try/catches since some enum values might be invalid
    $backupItemsVM = try { Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $vaultToDelete.ID -ErrorAction Stop } catch {}
    $backupItemsSQL = try { Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType MSSQL -VaultId $vaultToDelete.ID -ErrorAction Stop } catch {}
    $backupItemsAFS = try { Get-AzRecoveryServicesBackupItem -BackupManagementType AzureStorage -WorkloadType AzureFiles -VaultId $vaultToDelete.ID -ErrorAction Stop } catch {}
    $backupItemsSAP = try { Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType SAPHanaDatabase -VaultId $vaultToDelete.ID -ErrorAction Stop } catch {}
    $backupContainersSQL = try { Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -Status Registered -VaultId $vaultToDelete.ID -ErrorAction Stop | Where-Object { $_.ExtendedInfo.WorkloadType -eq "SQL" } } catch {}
    $protectableItemsSQL = try { Get-AzRecoveryServicesBackupProtectableItem -WorkloadType MSSQL -VaultId $vaultToDelete.ID -ErrorAction Stop | Where-Object { $_.IsAutoProtected -eq $true } } catch {}
    $backupContainersSAP = try { Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -Status Registered -VaultId $vaultToDelete.ID -ErrorAction Stop | Where-Object { $_.ExtendedInfo.WorkloadType -eq "SAPHana" } } catch {}
    $StorageAccounts = try { Get-AzRecoveryServicesBackupContainer -ContainerType AzureStorage -Status Registered -VaultId $vaultToDelete.ID -ErrorAction Stop } catch {}
    $backupServersMARS = try { Get-AzRecoveryServicesBackupContainer -ContainerType "Windows" -BackupManagementType MAB -VaultId $vaultToDelete.ID -ErrorAction Stop } catch {}
    $backupServersMABS = try { Get-AzRecoveryServicesBackupManagementServer -VaultId $vaultToDelete.ID -ErrorAction Stop | Where-Object { $_.BackupManagementType -eq "AzureBackupServer" } } catch {}
    $backupServersDPM = try { Get-AzRecoveryServicesBackupManagementServer -VaultId $vaultToDelete.ID -ErrorAction Stop | Where-Object { $_.BackupManagementType -eq "SCDPM" } } catch {}
    $pvtendpoints = try { Get-AzPrivateEndpointConnection -PrivateLinkResourceId $vaultToDelete.ID -ErrorAction Stop } catch {}

    $pool = New-RunspacePool -Variable (Get-Variable vaultToDelete) -ThrottleLimit 20
    $jobs = [system.Collections.ArrayList]::new()

    foreach ($item in $backupItemsVM)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $vaultToDelete.ID -RemoveRecoveryPoints -Force } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupItemsSQL)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $vaultToDelete.ID -RemoveRecoveryPoints -Force } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $protectableItems)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Disable-AzRecoveryServicesBackupAutoProtection -BackupManagementType AzureWorkload -WorkloadType MSSQL -InputItem $item -VaultId $vaultToDelete.ID } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupContainersSQL)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $vaultToDelete.ID } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupItemsSAP)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $vaultToDelete.ID -RemoveRecoveryPoints -Force } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupContainersSAP)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $vaultToDelete.ID } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupItemsAFS)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $vaultToDelete.ID -RemoveRecoveryPoints -Force } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $StorageAccounts)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Unregister-AzRecoveryServicesBackupContainer -container $item -Force -VaultId $vaultToDelete.ID } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupServersMARS)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $vaultToDelete.ID } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupServersMABS)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Unregister-AzRecoveryServicesBackupManagementServer -AzureRmBackupManagementServer $item -VaultId $vaultToDelete.ID } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupServersDPM)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Unregister-AzRecoveryServicesBackupManagementServer -AzureRmBackupManagementServer $item -VaultId $vaultToDelete.ID } -RunspacePool $pool -Argument $item))
    }

    $null = Wait-RunspaceJob -RunspaceJob $jobs
    Remove-RunspacePool -RunspacePool $pool

    #Deletion of ASR Items
    $fabricObjects = Get-AzRecoveryServicesAsrFabric
    # First DisableDR all VMs.
    foreach ($fabricObject in $fabricObjects)
    {
        $containerObjects = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabricObject -ErrorAction SilentlyContinue
        foreach ($containerObject in $containerObjects)
        {
            $protectedItems = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $containerObject -ErrorAction SilentlyContinue
            # DisableDR all protected items
            foreach ($protectedItem in $protectedItems)
            {
                $null = Remove-AzRecoveryServicesAsrReplicationProtectedItem -InputObject $protectedItem -Force
            }

            $containerMappings = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $containerObject
            # Remove all Container Mappings
            foreach ($containerMapping in $containerMappings)
            {
                $null = Remove-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainerMapping $containerMapping -Force
            }
        }
        $networkObjects = Get-AzRecoveryServicesAsrNetwork -Fabric $fabricObject
        foreach ($networkObject in $networkObjects)
        {
            #Get the PrimaryNetwork
            $PrimaryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $fabricObject -FriendlyName $networkObject
            $NetworkMappings = Get-AzRecoveryServicesAsrNetworkMapping -Network $PrimaryNetwork
            foreach ($networkMappingObject in $NetworkMappings)
            {
                #Get the Neetwork Mappings
                $NetworkMapping = Get-AzRecoveryServicesAsrNetworkMapping -Name $networkMappingObject.Name -Network $PrimaryNetwork
                $null = Remove-AzRecoveryServicesAsrNetworkMapping -InputObject $NetworkMapping
            }
        }
        # Remove Fabric
        $null = Remove-AzRecoveryServicesAsrFabric -InputObject $fabricObject -Force
    }

    foreach ($item in $pvtendpoints)
    {
        $penamesplit = $item.Name.Split(".")
        $pename = $penamesplit[0]
        $null = Remove-AzPrivateEndpointConnection -ResourceId $item.PrivateEndpoint.Id -Force #remove private endpoint connections
        $null = Remove-AzPrivateEndpoint -Name $pename -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -Force #remove private endpoints
    }

    try
    {
        $null = Remove-AzRecoveryServicesVault -Vault $vaultToDelete -Confirm:$false -ErrorAction Stop
    }
    catch
    {
        if ($RetryCount -le 2)
        {
            Remove-LWAzureRecoveryServicesVault -RetryCount ($RetryCount + 1)
        }
    }
    Write-LogFunctionExit
}
