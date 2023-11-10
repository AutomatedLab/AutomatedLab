function Get-LabVM
{
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([AutomatedLab.Machine])]
    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByRole')]
        [AutomatedLab.Roles]$Role,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All,

        [scriptblock]$Filter,

        [switch]$IncludeLinux,

        [switch]$IsRunning,

        [Switch]$SkipConnectionInfo
    )

    begin
    {
        #required to suporess verbose messages, warnings and errors
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        Write-LogFunctionEntry

        $result = @()
        $script:data = Get-Lab -ErrorAction SilentlyContinue
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            if ($ComputerName)
            {
                foreach ($n in $ComputerName)
                {
                    $machine = $Script:data.Machines | Where-Object Name -Like $n
                    if (-not $machine)
                    {
                        continue
                    }

                    $result += $machine
                }
            }
            else
            {
                $result = $Script:data.Machines
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'ByRole')
        {
            $result = $Script:data.Machines |
            Where-Object { $_.Roles.Name } |
            Where-Object { $_.Roles | Where-Object { $Role.HasFlag([AutomatedLab.Roles]$_.Name) } }

            if (-not $result)
            {
                return
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $result = $Script:data.Machines
        }

        # Skip Linux machines by default
        if (-not $IncludeLinux)
        {
            $result = $result | Where-Object -Property OperatingSystemType -eq Windows
        }
    }

    end
    {
        #Add Azure Connection Info
        $azureVMs = $Script:data.Machines | Where-Object { -not $_.SkipDeployment -and $_.HostType -eq 'Azure' -and -not $_.AzureConnectionInfo.DnsName }
        if ($azureVMs -and -not $SkipConnectionInfo.IsPresent)
        {
            $azureConnectionInfo = Get-LWAzureVMConnectionInfo -ComputerName $azureVMs

            if ($azureConnectionInfo)
            {
                foreach ($azureVM in $azureVMs)
                {
                    $azureVM | Add-Member -Name AzureConnectionInfo -MemberType NoteProperty -Value ($azureConnectionInfo | Where-Object ComputerName -eq $azureVM) -Force
                }
            }
        }

        $result = if ($IsRunning)
        {
            if ($result.Count -eq 1)
            {
                if ((Get-LabVMStatus -ComputerName $result) -eq 'Started')
                {
                    $result
                }
            }
            else
            {
                $startedMachines = (Get-LabVMStatus -ComputerName $result).GetEnumerator() | Where-Object Value -EQ Started
                $Script:data.Machines | Where-Object { $_.Name -in $startedMachines.Name }
            }
        }
        else
        {
            $result
        }
        
        foreach ($machine in ($result | Where-Object HostType -eq 'HyperV'))
        {
            if ($machine.Disks.Count -gt 1)
            {
                $machine.Disks = Get-LabVHDX -Name $machine.Disks.Name -ErrorAction SilentlyContinue
            }
        }

        if ($Filter)
        {
            $result.Where($Filter)
        }
        else
        {
            $result
        }
    }
}
