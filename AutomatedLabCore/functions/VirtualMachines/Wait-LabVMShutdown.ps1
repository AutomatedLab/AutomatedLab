function Wait-LabVMShutdown
{
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName,

        [double]$TimeoutInMinutes = (Get-LabConfigurationItem -Name Timeout_WaitLabMachine_Online),

        [ValidateRange(0, 300)]
        [int]$ProgressIndicator = (Get-LabConfigurationItem -Name DefaultProgressIndicator),

        [switch]$NoNewLine
    )

    begin
    {
        Write-LogFunctionEntry

        $start = Get-Date
        $lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }

        $vms = [System.Collections.Generic.List[AutomatedLab.Machine]]::new()
    }

    process
    {
        $null = Get-LabVM -ComputerName $ComputerName |
            Add-Member -Name HasShutdown -MemberType NoteProperty -Value $false -Force -PassThru |
            Foreach-Object {$vms.Add($_)}
    }

    end
    {
        $ProgressIndicatorTimer = Get-Date
        do
        {
            foreach ($vm in $vms)
            {
                $status = Get-LabVMStatus -ComputerName $vm -Verbose:$false

                if ($status -eq 'Stopped')
                {
                    $vm.HasShutdown = $true
                }
                else
                {
                    Start-Sleep -Seconds 5
                }
            }
            if (((Get-Date) - $ProgressIndicatorTimer).TotalSeconds -ge $ProgressIndicator)
            {
                Write-ProgressIndicator
                $ProgressIndicatorTimer = (Get-Date)
            }
        }
        until (($vms | Where-Object { $_.HasShutdown }).Count -eq $vms.Count -or (Get-Date).AddMinutes(- $TimeoutInMinutes) -gt $start)

        foreach ($vm in ($vms | Where-Object { -not $_.HasShutdown }))
        {
            Write-Error -Message "Timeout while waiting for computer '$($vm.Name)' to shutdown." -TargetObject $vm.Name -ErrorVariable shutdownError
        }

        if ($shutdownError)
        {
            Write-Error "The following machines have not shutdown in the timeout of $TimeoutInMinutes minute(s): $($shutdownError.TargetObject -join ', ')"
        }

        Write-LogFunctionExit
    }
}
