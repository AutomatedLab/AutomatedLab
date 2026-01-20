function Remove-LWProxmoxVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCmdlets', '', Justification = 'Not relevant on Linux')]
    [Cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    $PSBoundParameters.Add('ProgressIndicator', 1) #enables progress indicator
    if ($Machine.SkipDeployment)
    {
        return
    }

    Write-LogFunctionEntry

    Write-ScreenInfo -Message "Removing Proxmox VM '$Name'"

    $vm = Get-LWProxmoxVM -Name $Name
    $vm = Get-LWProxmoxVM -Name $Name -Node $vm.Node -NoCache #to refresh the status
    if (-not $vm)
    {
        Write-PSFMessage -Message "Proxmox VM '$Name' does not exist. Skipping removal." -Level 'Verbose'
        Write-LogFunctionExit
        return
    }

    if ($vm.status -ne 'stopped')
    {
        Write-ScreenInfo -Message "Stopping Proxmox VM '$Name' before removal"
        $result = Stop-PveVm -VmIdOrName $vm.VmId
        $values = @{
            status = 'stopped'
        }
        Wait-LWProxmoxTasksStatus -Upid $result.Response.data -Node $vm.node -DesiredValues $values -TimeoutInSeconds 600
    }

    $result = Remove-PveQemu -Node $vm.node -Vmid $vm.VmId #-Purge $true -DestroyUnreferencedDisks $true
    if ($result.StatusCode -ne 200)
    {
        Write-Error "Could not remove Proxmox machine '$Name': The error was '$($result.StatusCode)'" -ErrorAction Stop
    }

    $values = @{
        status = 'stopped'
    }
    Wait-LWProxmoxTasksStatus -Upid $result.Response.data -Node $vm.node -DesiredValues $values -TimeoutInSeconds 600

    Write-LogFunctionExit
}
