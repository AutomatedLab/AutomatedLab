function Wait-LWVMWareRestartVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
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

    Write-PSFMessage "Starting monitoring the servers at '$start'"

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
                Write-PSFMessage "VM '$machine' has been restarted"
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
