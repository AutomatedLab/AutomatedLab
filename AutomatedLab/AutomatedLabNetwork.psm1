#region New-LabNetworkSwitches
function New-LabNetworkSwitches
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param ()
    
    Write-LogFunctionEntry

    $Script:data = Get-Lab
    if (-not $Script:data)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    Write-Verbose "Creating network switch '$($virtualNetwork.Name)'..."

    $VMwareNetworks = $data.VirtualNetworks | Where-Object HostType -eq VMware
    if ($VMwareNetworks)
    {
        New-LWVMwareNetworkSwitch -VirtualNetwork $VMwareNetworks
    }

    $hypervNetworks = $data.VirtualNetworks | Where-Object HostType -eq HyperV
    if ($hypervNetworks)
    {
        New-LWHypervNetworkSwitch -VirtualNetwork $hypervNetworks
    }

    $azureNetworks = $data.VirtualNetworks | Where-Object HostType -eq Azure
    if ($azureNetworks )
    {
        New-LWAzureNetworkSwitch -VirtualNetwork $azureNetworks 
    }    

    Write-Verbose 'done'

    Write-LogFunctionExit
}
#endregion New-LabNetworkSwitches

#region Remove-LabNetworkSwitches
function Remove-LabNetworkSwitches
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param ()
    
    $Script:data = Get-Lab
    if (-not $Script:data)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    Write-LogFunctionEntry

    $virtualNetworks = $Script:data.VirtualNetworks | Where-Object HostType -eq VMware
    foreach ($virtualNetwork in $virtualNetworks)
    {
        Write-Error "Cannot remove network '$virtualNetwork'. Managing networks is not yet supported for VMware"
        continue
    }

    $virtualNetworks = $Script:data.VirtualNetworks | Where-Object { $_.HostType -eq 'HyperV' -and $_.Name -ne 'Default Switch' }
    foreach ($virtualNetwork in $virtualNetworks)
    {
        Write-Verbose "Removing Hyper-V network switch '$($virtualNetwork.Name)'..."
        
        if ($virtualNetwork.SwitchType -eq 'External')
        {
            Write-ScreenInfo "The virtual switch '$($virtualNetwork.Name)' is of type external and will not be removed as it may also be used by other labs"
            continue
        }
        else
        {
            Remove-LWNetworkSwitch -Name $virtualNetwork.Name
        }
        Write-Verbose '...done'
    }
        
    Write-Verbose 'done'

    Write-LogFunctionExit
}
#endregion Remove-LabNetworkSwitches