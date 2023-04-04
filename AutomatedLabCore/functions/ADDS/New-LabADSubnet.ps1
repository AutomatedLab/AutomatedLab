function New-LabADSubnet
{
    [CmdletBinding()]
    param(
        [switch]$PassThru
    )

    Write-LogFunctionEntry

    $createSubnetScript = {
        param(
            $NetworkInfo
        )

        $PSDefaultParameterValues = @{
            '*-AD*:Server' = $env:COMPUTERNAME
        }

        #$defaultSite = Get-ADReplicationSite -Identity Default-First-Site-Name -Server localhost
        $ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext([System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Forest)
        $defaultSite = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::FindByName($ctx, 'Default-First-Site-Name')
        $subnetName = "$($NetworkInfo.Network)/$($NetworkInfo.MaskLength)"

        try
        {
            $subnet = Get-ADReplicationSubnet -Identity $subnetName -Server localhost
        }
        catch { }

        if (-not $subnet)
        {
            #New-ADReplicationSubnet seems to have a bug and reports Access Denied.
            #New-ADReplicationSubnet -Name $subnetName -Site $defaultSite -PassThru -Server localhost
            $subnet = New-Object System.DirectoryServices.ActiveDirectory.ActiveDirectorySubnet($ctx, $subnetName)
            $subnet.Site = $defaultSite
            $subnet.Save()
        }
    }

    $machines = Get-LabVM -Role RootDC, FirstChildDC
    $lab = Get-Lab

    foreach ($machine in $machines)
    {
        $ipAddress = ($machine.IpAddress -split '/')[0]
        
        if ($ipAddress -eq '0.0.0.0') {
            $ipAddress = Get-NetIPAddress -AddressFamily IPv4 | Where-Object InterfaceAlias -eq "vEthernet ($($machine.Network))"
        }
        $ipPrefix = ($machine.IpAddress -split '/')[1]
        $subnetMask = if ([int]$ipPrefix) {        
            $ipPrefix | ConvertTo-Mask
        }
        else {
            $ipAddress.PrefixLength | ConvertTo-Mask
            $ipAddress = $ipAddress.IPAddress
        }

        $networkInfo = Get-NetworkSummary -IPAddress $ipAddress -SubnetMask $subnetMask
        Write-PSFMessage -Message "Creating subnet '$($networkInfo.Network)' with mask '$($networkInfo.MaskLength)' on machine '$($machine.Name)'"

        #if the machine is not a Root Domain Controller
        if (-not ($machine.Roles | Where-Object { $_.Name -eq 'RootDC'}))
        {
            $rootDc = $machines | Where-Object { $_.Roles.Name -eq 'RootDC' -and $_.DomainName -eq $lab.GetParentDomain($machine.DomainName) }
        }
        else
        {
            $rootDc = $machine
        }

        if ($rootDc)
        {
            Invoke-LabCommand -ComputerName $rootDc -ActivityName 'Create AD Subnet' -NoDisplay `
            -ScriptBlock $createSubnetScript -AsJob -ArgumentList $networkInfo
        }
        else
        {
            Write-ScreenInfo -Message 'Root domain controller could not be found, cannot Create AD Subnet automatically.' -Type Warning
        }
    }

    Write-LogFunctionExit
}
