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
    $virtualNetworks = Get-LabVirtualNetwork -Name $virtualNetworks.Name -ErrorAction SilentlyContinue
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
            if (-not $virtualNetwork.Notes)
            {
                Write-Error -Message "Cannot remove virtual network '$virtualNetwork' because lab meta data for this object could not be retrieved"
            }
            elseif ($virtualNetwork.Notes.LabName -ne $labName)
            {
                Write-Error -Message "Cannot remove virtual network '$virtualNetwork' because it does not belong to this lab"
            }
            else
            {
                Remove-LWNetworkSwitch -Name $virtualNetwork.ResourceName
            }
        }
        Write-PSFMessage '...done'
    }

    Write-PSFMessage 'done'

    Write-LogFunctionExit
}
