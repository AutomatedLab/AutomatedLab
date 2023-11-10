function New-LWVMWareVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ReferenceVM,

        [Parameter(Mandatory)]
        [string]$AdminUserName,

        [Parameter(Mandatory)]
        [string]$AdminPassword,

        [Parameter(ParameterSetName = 'DomainJoin')]
        [string]$DomainName,

        [Parameter(Mandatory, ParameterSetName = 'DomainJoin')]
        [pscredential]$DomainJoinCredential,

        [switch]$AsJob,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    $lab = Get-Lab

    #TODO: add logic to determine if machine already exists
    <#
            if (VMware.VimAutomation.Core\Get-VM -Name $Machine.Name -ErrorAction SilentlyContinue)
            {
            Write-ProgressIndicatorEnd
            Write-ScreenInfo -Message "The machine '$Machine' does already exist" -Type Warning
            return $false
            }

            Write-Verbose "Creating machine with the name '$($Machine.Name)' in the path '$VmPath'"

    #>

    $folderName = "AutomatedLab_$($lab.Name)"
    if (-not (Get-Folder -Name $folderName -ErrorAction SilentlyContinue))
    {
        New-Folder -Name $folderName -Location VM | out-null
    }


    $referenceSnapshot = (Get-Snapshot -VM (VMware.VimAutomation.Core\Get-VM $ReferenceVM)).Name | Select-Object -last 1

    $parameters = @{
        Name = $Name
        ReferenceVM = $ReferenceVM
        AdminUserName = $AdminUserName
        AdminPassword = $AdminPassword
        DomainName = $DomainName
        DomainCred = $DomainJoinCredential
        FolderName = $FolderName
    }

    if ($AsJob)
    {
        $job = Start-Job -ScriptBlock {
            throw 'Not implemented yet'  # TODO: implement
        } -ArgumentList $parameters


        if ($PassThru)
        {
            $job
        }
    }
    else
    {
        $osSpecs = Get-OSCustomizationSpec -Name AutomatedLabSpec -Type NonPersistent -ErrorAction SilentlyContinue
        if ($osSpecs)
        {
            Remove-OSCustomizationSpec -OSCustomizationSpec $osSpecs -Confirm:$false
        }

        if (-not $parameters.DomainName)
        {
            $osSpecs = New-OSCustomizationSpec -Name AutomatedLabSpec -FullName $parameters.AdminUserName -AdminPassword $parameters.AdminPassword `
            -OSType Windows -Type NonPersistent -OrgName AutomatedLab -Workgroup AutomatedLab -ChangeSid
            #$osSpecs = Get-OSCustomizationSpec -Name Standard | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $ipaddress -SubnetMask $netmask -DefaultGateway $gateway -Dns $DNS
        }
        else
        {
            $osSpecs = New-OSCustomizationSpec -Name AutomatedLabSpec -FullName $parameters.AdminUserName -AdminPassword $parameters.AdminPassword `
            -OSType Windows -Type NonPersistent -OrgName AutomatedLab -Domain $parameters.DomainName -DomainCredentials $DomainJoinCredential -ChangeSid
        }

        $ReferenceVM_int = VMware.VimAutomation.Core\Get-VM -Name $parameters.ReferenceVM
        if (-not $ReferenceVM_int)
        {
            Write-Error "Reference VM '$($parameters.ReferenceVM)' could not be found, cannot create the machine '$($machine.Name)'"
            return
        }

        # Create Linked Clone
        $result = VMware.VimAutomation.Core\New-VM `
        -Name $parameters.Name `
        -ResourcePool $lab.VMWareSettings.ResourcePool `
        -Datastore $lab.VMWareSettings.DataStore `
        -Location (Get-Folder -Name $parameters.FolderName) `
        -OSCustomizationSpec $osSpecs `
        -VM $ReferenceVM_int `
        -LinkedClone `
        -ReferenceSnapshot $referenceSnapshot `

        #TODO: logic to switch to full clone for AD recovery scenario's etc.
        <# Create full clone
                $result = VMware.VimAutomation.Core\New-VM `
                -Name $parameters.Name `
                -ResourcePool $lab.VMWareSettings.ResourcePool `
                -Datastore $lab.VMWareSettings.DataStore `
                -Location (Get-Folder -Name $parameters.FolderName) `
                -OSCustomizationSpec $osSpecs `
                -VM $ReferenceVM_int
        #>
    }

    if ($PassThru)
    {
        $result
    }

    Write-LogFunctionExit
}
