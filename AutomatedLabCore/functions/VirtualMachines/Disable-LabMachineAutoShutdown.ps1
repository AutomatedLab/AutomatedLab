function Disable-LabMachineAutoShutdown
{
    [CmdletBinding()]
    param
    (
        [string[]]
        $ComputerName
    )

    $lab = Get-Lab -ErrorAction Stop
    if ($ComputerName.Count -eq 0)
    {
        $ComputerName = Get-LabVm | Where-Object SkipDeployment -eq $false
    }

    switch ($lab.DefaultVirtualizationEngine)
    {
        'Azure' {Disable-LWAzureAutoShutdown @PSBoundParameters -Wait}
        'HyperV' {Write-ScreenInfo -Type Warning -Message "No auto-shutdown on HyperV"}
        'VMWare' {Write-ScreenInfo -Type Warning -Message "No auto-shutdown on VMWare"}
    }
}
