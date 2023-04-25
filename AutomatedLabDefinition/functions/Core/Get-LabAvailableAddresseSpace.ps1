function Get-LabAvailableAddresseSpace
{
    $defaultAddressSpace = Get-LabConfigurationItem -Name DefaultAddressSpace

    if (-not $defaultAddressSpace)
    {
        Write-Error 'Could not get the PrivateData value DefaultAddressSpace. Cannot find an available address space.'
        return
    }

    $existingHyperVVirtualSwitches = Get-LabVirtualNetwork

    $networkFound = $false
    $addressSpace = [AutomatedLab.IPNetwork]$defaultAddressSpace

    if ($null -eq $reservedAddressSpaces)
    {
        $script:reservedAddressSpaces = @() 
    }

    do
    {
        $addressSpace = $addressSpace.Increment()

        $conflictingSwitch = $existingHyperVVirtualSwitches | Where-Object AddressSpace -eq $addressSpace
        if ($conflictingSwitch)
        {
            Write-PSFMessage -Message "Network '$addressSpace' is in use by existing Hyper-V virtual switch '$conflictingSwitch'"
            continue
        }

        if ($addressSpace -in $reservedAddressSpaces)
        {
            Write-PSFMessage -Message "Network '$addressSpace' has already been defined in this lab"
            continue
        }

        $localAddresses = if ($IsLinux)
        {
            (ip -4 addr) | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
        }
        else
        {
            (Get-NetIPAddress -AddressFamily IPv4).IPAddress
        }

        if ($addressSpace.IpAddress -in $localAddresses)
        {
            Write-PSFMessage -Message "Network '$addressSpace' is in use locally"
            continue
        }

        $route = if ($IsLinux)
        {
            (route | Select-Object -First 5 -Skip 2 | ForEach-Object { '{0}/{1}' -f ($_ -split '\s+')[0], (ConvertTo-MaskLength ($_ -split '\s+')[2]) })
        }
        else
        {
            Get-NetRoute -DestinationPrefix $addressSpace.ToString() -ErrorAction SilentlyContinue
        }

        if ($null -ne $route)
        {
            Write-PSFMessage -Message "Network '$addressSpace' is routable"
            continue
        }

        $networkFound = $true
    }
    until ($networkFound)

    $script:reservedAddressSpaces += $addressSpace
    $addressSpace
}
