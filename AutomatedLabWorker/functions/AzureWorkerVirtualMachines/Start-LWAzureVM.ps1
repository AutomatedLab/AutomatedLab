function Start-LWAzureVM
{
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,

        [int]$DelayBetweenComputers = 0,

        [int]$ProgressIndicator = 15,

        [switch]$NoNewLine
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount
    $machines = Get-LabVm -ComputerName $ComputerName -IncludeLinux

    $azureVms = Get-LWAzureVm -ComputerName $ComputerName

    $stoppedAzureVms = $azureVms | Where-Object { $_.PowerState -ne 'VM running' -and $_.Name -in $machines.ResourceName }

    $lab = Get-Lab

    $machinesToJoin = @()

    if ($stoppedAzureVms)
    {
        $jobs = foreach ($name in $machines.ResourceName)
        {
            $vm = $azureVms | Where-Object Name -eq $name
            $vm | Start-AzVM -AsJob
        }

        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator $ProgressIndicator
    }

    # Refresh status
    $azureVms = Get-LWAzureVm -ComputerName $ComputerName

    $azureVms = $azureVms | Where-Object { $_.Name -in $machines.ResourceName }

    foreach ($machine in $machines)
    {
        $vm = $azureVms | Where-Object Name -eq $machine.ResourceName

        if ($vm.PowerState -ne 'VM Running')
        {
            throw "Could not start machine '$machine'"
        }
        else
        {
            if ($machine.IsDomainJoined -and -not $machine.HasDomainJoined -and ($machine.Roles.Name -notcontains 'RootDC' -and $machine.Roles.Name -notcontains 'FirstChildDC' -and $machine.Roles.Name -notcontains 'DC'))
            {
                $machinesToJoin += $machine
            }
        }
    }

    if ($machinesToJoin)
    {
        Write-PSFMessage -Message "Waiting for machines '$($machinesToJoin -join ', ')' to come online"
        Wait-LabVM -ComputerName $machinesToJoin -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine

        Write-PSFMessage -Message 'Start joining the machines to the respective domains'
        Join-LabVMDomain -Machine $machinesToJoin
    }

    Write-LogFunctionExit
}
