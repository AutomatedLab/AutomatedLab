function Restart-LabVM
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName,

        [switch]$Wait,

        [double]$ShutdownTimeoutInMinutes = (Get-LabConfigurationItem -Name Timeout_RestartLabMachine_Shutdown),

        [ValidateRange(0, 300)]
        [int]$ProgressIndicator = (Get-LabConfigurationItem -Name DefaultProgressIndicator),

        [switch]$NoDisplay,

        [switch]$NoNewLine
    )

    begin
    {
        Write-LogFunctionEntry

        $lab = Get-Lab
        if (-not $lab.Machines)
        {
            Write-Error 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }
    }

    process
    {
        $machines = Get-LabVM -ComputerName $ComputerName | Where-Object SkipDeployment -eq $false

        if (-not $machines)
        {
            Write-Error "The machines '$($ComputerName -join ', ')' could not be found in the lab."
            return
        }

        Write-PSFMessage "Stopping machine '$ComputerName' and waiting for shutdown"
        Stop-LabVM -ComputerName $ComputerName -ShutdownTimeoutInMinutes $ShutdownTimeoutInMinutes -Wait -ProgressIndicator $ProgressIndicator -NoNewLine -KeepAzureVmProvisioned
        Write-PSFMessage "Machine '$ComputerName' is stopped"

        Write-Debug 'Waiting 10 seconds'
        Start-Sleep -Seconds 10

        Write-PSFMessage "Starting machine '$ComputerName' and waiting for availability"
        Start-LabVM -ComputerName $ComputerName -Wait:$Wait -ProgressIndicator $ProgressIndicator -NoNewline:$NoNewLine
        Write-PSFMessage "Machine '$ComputerName' is started"
    }

    end
    {
        Write-LogFunctionExit
    }
}
