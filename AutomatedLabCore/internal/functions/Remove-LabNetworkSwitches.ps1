function Remove-LabNetworkSwitches
{
    [cmdletBinding()]
    param (
        [switch]$RemoveExternalSwitches
    )

    $Script:data = Get-Lab
    if (-not $Script:data)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    Write-LogFunctionEntry

    $virtualNetworks = $Script:data.VirtualNetworks | Where-Object HostType -eq VMWare
    foreach ($virtualNetwork in $virtualNetworks)
    {
        Write-Error "Cannot remove network '$virtualNetwork'. Managing networks is not yet supported for VMWare"
        continue
    }

    $virtualNetworks = $Script:data.VirtualNetworks | Where-Object { $_.HostType -eq 'HyperV' -and $_.Name -ne 'Default Switch' }
    foreach ($virtualNetwork in $virtualNetworks)
    {
        Write-PSFMessage "Removing Hyper-V network switch '$($virtualNetwork.ResourceName)'..."

        if ($virtualNetwork.SwitchType -eq 'External' -and -not $RemoveExternalSwitches)
        {
            Write-ScreenInfo "The virtual switch '$($virtualNetwork.ResourceName)' is of type external and will not be removed as it may also be used by other labs"
            continue
        }
        else
        {
            Remove-LWNetworkSwitch -Name $virtualNetwork.ResourceName
        }
        Write-PSFMessage '...done'
    }

    Write-PSFMessage 'done'

    Write-LogFunctionExit
}
