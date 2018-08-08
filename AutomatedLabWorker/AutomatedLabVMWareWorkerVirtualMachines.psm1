<#
    An AutomatedLab user could have a VMware environment on premises _and_ have Hyper-V enabled on his own device.
    When the user has both Hyper-V and VMware modules loaded in one session, this can cause unwanted behaviour.

    This may need to be mitigated in AutomatedLab in some cases. There are two main approaches:
    1) Prepending conflicting CmdLets with the name of the intende module of origin, e.g.:
    VMware.VimAutomatiion.Core\Get-VM

    2) Theoretically, one should be able to load modules using the -Prefix parameter:
    Import-Module VMware* -Prefix "VW"
    This _should_ result in all the VMware CmdLets being imported with the prefix VW:
    Get-VWVM
    Unfortunately, this does not work in PowerCLI 6.0R2 - 6.5.0 , because of the way the underlying PSSnapin is loaded.
    See here for more information:
    https://communities.vmware.com/thread/520601
    This will be solved in PowerCLI version 6.5.1 R1:
    https://blogs.vmware.com/PowerCLI/2016/11/saying-farewell-snapins.html

    For now, approach 1) is probably the way to go, or we should force users to require version 6.5.1R1 or greater for the VMware module.

    Get a list of CmdLets whith the same name in Hyper-V and VMware:
    Compare-Object (get-command -Module VMware.VimAutomation.Core) (Get-Command -Module Hyper-V) -IncludeEqual -ExcludeDifferent
    Retrieved 30-5-2017, VMware module version:6.3.0.0, Hyper-V module version 2.0.0.0

    InputObject SideIndicator
    ----------- -------------
    Get-VM      ==
    Get-VMHost  ==
    Move-VM     ==
    New-VM      ==
    Remove-VM   ==
    Restart-VM  ==
    Set-VM      ==
    Set-VMHost  ==
    Start-VM    ==
    Stop-VM     ==
    Suspend-VM  ==
#>

trap
{
    if ((($_.Exception.Message -like '*Get-VM*') -or `
            ($_.Exception.Message -like '*Save-VM*') -or `
            ($_.Exception.Message -like '*Get-VMSnapshot*') -or `
            ($_.Exception.Message -like '*Suspend-VM*') -or `
        ($_.Exception.Message -like '*CheckPoint-VM*')) -and `
    (-not (Get-Module -ListAvailable Hyper-V)))
    {
        # What is the exact purpose of this error trap?
        # Errors concerning certain CmdLets are to be ignored, if Hyper-V is not an available module. Why?
    }
    else
    {
        Write-Error $_
    }
    continue
}

#region New-LWVMwareVM
function New-LWVMwareVM
{
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine]$Machine,

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

    if (VMware.VimAutomation.Core\Get-VM -Name $Machine.Name -ErrorAction SilentlyContinue)
    {
        Write-ProgressIndicatorEnd
        Write-ScreenInfo -Message "The machine '$($Machine.Name)' does already exist" -Type Warning
        return $false
    }

    $lab = Get-Lab

    $folderName = "AutomatedLab_$($lab.Name)"
    if (-not (Get-Folder -Name $folderName -ErrorAction SilentlyContinue))
    {
        New-Folder -Name $folderName -Location VM | out-null
    }

    Write-Verbose "Creating machine with the name '$Machine' in the VMware Folder '$folderName'"

    $referenceSnapshot = (Get-Snapshot -VM (VMware.VimAutomation.Core\Get-VM $ReferenceVM)).Name | Select -Last 1

    $parameters = @{
        Name = $Machine.Name
        ReferenceVM = $ReferenceVM
        AdminUserName = $AdminUserName
        AdminPassword = $AdminPassword
        DomainName = $DomainName
        DomainCred = $DomainJoinCredential
        AdminUserName = $Machine.InstallationUser.UserName
        AdminPassword = $Machine.InstallationUser.Password
        DomainName = $Machine.DomainName
        DomainCred = $Machine.GetCredential($lab)
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
            $osSpecs = New-OSCustomizationSpec `
                -Name AutomatedLabSpec `
                -FullName $parameters.AdminUserName `
                -AdminPassword $parameters.AdminPassword `
                -OSType Windows `
                -Type NonPersistent `
                -OrgName AutomatedLab `
                -Workgroup AutomatedLab `
                -ChangeSid
        }
        else
        {
            $osSpecs = New-OSCustomizationSpec `
                -Name AutomatedLabSpec `
                -FullName $parameters.AdminUserName `
                -AdminPassword $parameters.AdminPassword `
                -OSType Windows `
                -Type NonPersistent `
                -OrgName AutomatedLab `
                -Domain $parameters.DomainName `
                -DomainCredentials $DomainJoinCredential `
                -ChangeSid
        }

        # TODO: add check somewhere upstream that VMware may not support IPv66 in OSCustomizationNicMapping.
        $osSpecsWithNet = @()
        foreach ($netadapter in $Machine.NetworkAdapters )
        {
            [AutomatedLab.NetworkAdapter]$netadapter = $netadapter

            if ($netadapter.UseDhcp)
            {
                $osSpecsWithNet += $osSpecs | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping `
                    -IpMode UseDhcp`
                    -NetworkAdapterMac $netadapter.MacAddress
            }
            else {
                $osSpecsWithNet += $osSpecs | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping `
                    -IpMode UseStaticIp `
                    -IpAddress $netadapter.Ipv4Address[0].IpAddress `
                    -SubnetMask $netadapter.Ipv4Address[0].Netmask `
                    -DefaultGateway $netadapter.Ipv4Gateway `
                    -Dns $netadapter.Ipv4DnsServers `
                    -NetworkAdapterMac $netadapter.MacAddress
            }

        }

        $ReferenceVM_int = VMware.VimAutomation.Core\Get-VM -Name $parameters.ReferenceVM
        if (-not $ReferenceVM_int)
        {
            Write-Error "Reference VM '$($parameters.ReferenceVM)' could not be found, cannot create the machine '$($machine.Name)'"
            return
        }

        if ($Machine.Roles.Name -notcontains "DC") {
            # Create Linked Clone
            $result = VMware.VimAutomation.Core\New-VM `
                -Name $parameters.Name `
                -ResourcePool $lab.VMWareSettings.ResourcePool `
                -Datastore $lab.VMWareSettings.DataStore `
                -Location (Get-Folder -Name $parameters.FolderName) `
                -OSCustomizationSpec $osSpecsWithNet `
                -VM $ReferenceVM_int `
                -LinkedClone `
                -ReferenceSnapshot $referenceSnapshot `
        }
        else {
            #DC will be full clone for AD recovery scenarios etc.
            $result = VMware.VimAutomation.Core\New-VM `
                -Name $parameters.Name `
                -ResourcePool $lab.VMWareSettings.ResourcePool `
                -Datastore $lab.VMWareSettings.DataStore `
                -Location (Get-Folder -Name $parameters.FolderName) `
                -OSCustomizationSpec $osSpecs `
                -VM $ReferenceVM_int
        }
    }

    if ($PassThru)
    {
        $result
    }

    Write-LogFunctionExit
}
#endregion New-LWVM

#region Remove-LWVMwareVM
function Remove-LWVMwareVM
{
    Param (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [switch]$AsJob,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    if ($AsJob)
    {
        $job = Start-Job -ScriptBlock {
            param (
                [Parameter(Mandatory)]
                [hashtable]$ComputerName
            )

            Add-PSSnapin -Name VMware.VimAutomation.Core, VMware.VimAutomation.Vds

            $vm = VMware.VimAutomation.Core\Get-VM -Name $ComputerName
            if ($vm)
            {
                if ($vm.PowerState -eq "PoweredOn")
                {
                    VMware.VimAutomation.Core\Stop-VM -VM $vm -Confirm:$false
                }
                VMware.VimAutomation.Core\Remove-VM -DeletePermanently -VM $ComputerName -Confirm:$false
            }
        } -ArgumentList $ComputerName

        if ($PassThru)
        {
            $job
        }
    }
    else
    {
        $vm = VMware.VimAutomation.Core\Get-VM -Name $ComputerName
        if ($vm)
        {
            if ($vm.PowerState -eq "PoweredOn")
            {
                VMware.VimAutomation.Core\Stop-VM -VM $vm -Confirm:$false
            }
            VMware.VimAutomation.Core\Remove-VM -DeletePermanently -VM $ComputerName -Confirm:$false
        }
    }

    Write-LogFunctionExit
}
#endregion Remove-LWVMwareVM

#region Start-LWVMwareVM
function Start-LWVMwareVM
{
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,

        [int]$DelayBetweenComputers = 0
    )

    Write-LogFunctionEntry

    foreach ($name in $ComputerName)
    {
        $vm = $null
        $vm = VMware.VimAutomation.Core\Get-VM -Name $name
        if ($vm)
        {
            VMware.VimAutomation.Core\Start-VM $vm -ErrorAction SilentlyContinue | Out-Null
            $result = VMware.VimAutomation.Core\Get-VM $vm
            if ($result.PowerState -ne "PoweredOn")
            {
                Write-Error "Could not start machine '$name'"
            }
        }
        Start-Sleep -Seconds $DelayBetweenComputers
    }

    Write-LogFunctionExit
}
#endregion Start-LWVMwareVM

#region Save-LWVMwareVM
function Save-LWVMwareVM
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    VMware.VimAutomation.Core\Suspend-VM -VM $ComputerName -ErrorAction SilentlyContinue -Confirm:$false

    Write-LogFunctionExit
}
#endregion Save-LWVMwareVM

#region Stop-LWVMwareVM
function Stop-LWVMwareVM
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    foreach ($name in $ComputerName)
    {
        if (VMware.VimAutomation.Core\Get-VM -Name $name)
        {
            $result = Shutdown-VMGuest -VM $name -ErrorAction SilentlyContinue -Confirm:$false
            if ($result.PowerState -ne "PoweredOff")
            {
                Write-Error "Could not stop machine '$name'"
            }
        }
        else
        {
            Write-ScreenInfo "The machine '$name' does not exist on the connected ESX Server" -Type Warning
        }
    }

    Write-LogFunctionExit
}
#endregion Stop-LWVMwareVM

#region Wait-LWVMwareRestartVM
function Wait-LWVMwareRestartVM
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [double]$TimeoutInMinutes = 15
    )

    Write-LogFunctionEntry

    $prevErrorActionPreference = $Global:ErrorActionPreference
    $Global:ErrorActionPreference = 'SilentlyContinue'
    $preVerboseActionPreference = $Global:VerbosePreference
    $Global:VerbosePreference = 'SilentlyContinue'

    $start = Get-Date

    Write-Verbose "Starting monitoring the servers at '$start'"

    $machines = Get-LabVM -ComputerName $ComputerName

    $cmd = {
        param (
            [datetime]$Start
        )

        $events = Get-EventLog -LogName System -InstanceId 2147489653 -After $Start -Before $Start.AddHours(1)

        $events
    }

    do
    {
        $azureVmsToWait = foreach ($machine in $machines)
        {
            $events = Invoke-LabCommand -ComputerName $machine -ActivityName WaitForRestartEvent -ScriptBlock $cmd -ArgumentList $start.Ticks -UseLocalCredential -PassThru

            if ($events)
            {
                Write-Verbose "VM '$machine' has been restarted"
            }
            else
            {
                $machine
            }
            Start-Sleep -Seconds 15
        }
    }
    until ($azureVmsToWait.Count -eq 0 -or (Get-Date).AddMinutes(- $TimeoutInMinutes) -gt $start)

    $Global:ErrorActionPreference = $prevErrorActionPreference
    $Global:VerbosePreference = $preVerboseActionPreference

    if ((Get-Date).AddMinutes(- $TimeoutInMinutes) -gt $start)
    {
        Write-Error -Message "Timeout while waiting for computers to restart. Computers not restarted: $($azureVmsToWait.Name -join ', ')"
    }

    Write-LogFunctionExit
}
#endregion Wait-LWVMwareRestartVM

#region Get-LWVMwareVMStatus
function Get-LWVMwareVMStatus
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    $result = @{ }

    foreach ($name in $ComputerName)
    {
        $vm = VMware.VimAutomation.Core\Get-VM -Name $name
        if ($vm)
        {
            if ($vm.PowerState -eq 'PoweredOn')
            {
                $result.Add($vm.Name, 'Started')
            }
            elseif ($vm.PowerState -eq 'PoweredOff')
            {
                $result.Add($vm.Name, 'Stopped')
            }
            else
            {
                $result.Add($vm.Name, 'Unknown')
            }
        }
    }

    $result

    Write-LogFunctionExit
}
#endregion Get-LWVMwareVMStatus

#region Enable-LWVMwareVMRemoting
function Enable-LWVMwareVMRemoting
{
    param(
        [Parameter(Mandatory, Position = 0)]
        $ComputerName
    )

    if ($ComputerName)
    {
        $machines = Get-LabVM -All | Where-Object Name -in $ComputerName
    }
    else
    {
        $machines = Get-LabVM -All
    }

    $script = {
        param ($DomainName, $UserName, $Password)

        $VerbosePreference = 'Continue'

        $RegPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

        Set-ItemProperty -Path $RegPath -Name AutoAdminLogon -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $RegPath -Name DefaultUserName -Value $UserName -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $RegPath -Name DefaultPassword -Value $Password -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $RegPath -Name DefaultDomainName -Value $DomainName -ErrorAction SilentlyContinue

        Enable-WSManCredSSP -Role Server -Force | Out-Null
    }

    foreach ($machine in $machines)
    {
        $cred = $machine.GetCredential((Get-Lab))
        try
        {
            Invoke-LabCommand -ComputerName $machine -ActivityName SetLabVMRemoting -ScriptBlock $script `
            -ArgumentList $machine.DomainName, $cred.UserName, $cred.GetNetworkCredential().Password -ErrorAction Stop -Verbose
        }
        catch
        {
            Connect-WSMan -ComputerName $machine -Credential $cred
            Set-Item -Path "WSMan:\$machine\Service\Auth\CredSSP" -Value $true
            Disconnect-WSMan -ComputerName $machine
        }
    }
}
#endregion Enable-LWVMwareVMRemoting