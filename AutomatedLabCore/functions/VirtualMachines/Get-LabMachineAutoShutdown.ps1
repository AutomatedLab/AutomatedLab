function Get-LabMachineAutoShutdown
{
    [CmdletBinding()]
    param
    ( )

    $lab = Get-Lab -ErrorAction Stop

    switch ($lab.DefaultVirtualizationEngine)
    {
        'Azure' {Get-LWAzureAutoShutdown}
        'HyperV' {Write-ScreenInfo -Type Warning -Message "No auto-shutdown on HyperV"}
        'VMWare' {Write-ScreenInfo -Type Warning -Message "No auto-shutdown on VMWare"}
    }
}
