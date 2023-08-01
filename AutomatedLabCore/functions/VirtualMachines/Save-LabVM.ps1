function Save-LabVM
{
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByName', Position = 0)]
        [string[]]$Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByRole')]
        [AutomatedLab.Roles]$RoleName,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'All')]
        [switch]$All
    )

    begin
    {
        Write-LogFunctionEntry

        $lab = Get-Lab

        $vms = @()
        $availableVMs = ($lab.Machines  | Where-Object SkipDeployment -eq $false).Name
    }

    process
    {

        if (-not $lab.Machines)
        {
            $message = 'No machine definitions imported, please use Import-Lab first'
            Write-Error -Message $message
            Write-LogFunctionExitWithError -Message $message
            return
        }

        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            $Name | ForEach-Object {
                if ($_ -in $availableVMs)
                {
                    $vms += $_
                }
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByRole')
        {
            #get all machines that have a role assigned and the machine's role name is part of the parameter RoleName
            $machines = ($lab.Machines |
                Where-Object { $_.Roles.Name } |
            Where-Object { $_.Roles | Where-Object { $RoleName.HasFlag([AutomatedLab.Roles]$_.Name) } }).Name
            $vms = $machines
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $vms = $availableVMs
        }
    }

    end
    {
        $vms = Get-LabVM -ComputerName $vms -IncludeLinux

        #if there are no VMs to start, just write a warning
        if (-not $vms)
        {
            Write-ScreenInfo 'There is no machine to start' -Type Warning
            return
        }

        Write-PSFMessage -Message "Saving VMs '$($vms -join ',')"
        switch ($lab.DefaultVirtualizationEngine)
        {
            'HyperV' { Save-LWHypervVM -ComputerName $vms.ResourceName}
            'VMWare' { Save-LWVMWareVM -ComputerName $vms.ResourceName}
            'Azure'  { Write-PSFMessage -Level Warning -Message "Skipping Azure VMs '$($vms -join ',')' as suspending the VMs is not supported on Azure."}
        }

        Write-LogFunctionExit
    }
}
