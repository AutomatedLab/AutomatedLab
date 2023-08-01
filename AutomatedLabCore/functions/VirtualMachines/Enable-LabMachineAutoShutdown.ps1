function Enable-LabMachineAutoShutdown
{
    [CmdletBinding()]
    param
    (
        [string[]]
        $ComputerName,

        [Parameter(Mandatory)]
        [TimeSpan]
        $Time,

        [string]
        $TimeZone = (Get-TimeZone).Id
    )

    $lab = Get-Lab -ErrorAction Stop
    if ($ComputerName.Count -eq 0)
    {
        $ComputerName = Get-LabVm | Where-Object SkipDeployment -eq $false
    }

    switch ($lab.DefaultVirtualizationEngine)
    {
        'Azure' {Enable-LWAzureAutoShutdown @PSBoundParameters -Wait}
        'HyperV' {Write-ScreenInfo -Type Warning -Message "No auto-shutdown on HyperV"}
        'VMWare' {Write-ScreenInfo -Type Warning -Message "No auto-shutdown on VMWare"}
    }
}
