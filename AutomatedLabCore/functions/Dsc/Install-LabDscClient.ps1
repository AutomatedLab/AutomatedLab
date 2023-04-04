function Install-LabDscClient
{
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All,

        [string[]]$PullServer
    )

    if ($All)
    {
        $machines = Get-LabVM | Where-Object { $_.Roles.Name -notin 'DC', 'RootDC', 'FirstChildDC', 'DSCPullServer' }
    }
    else
    {
        $machines = Get-LabVM -ComputerName $ComputerName
    }

    if (-not $machines)
    {
        Write-Error 'Machines to configure DSC Pull not defined or not found in the lab.'
        return
    }

    Start-LabVM -ComputerName $machines -Wait

    if ($PullServer)
    {
        if (-not (Get-LabVM -ComputerName $PullServer | Where-Object { $_.Roles.Name -contains 'DSCPullServer' }))
        {
            Write-Error "The given DSC Pull Server '$PullServer' could not be found in the lab."
            return
        }
        else
        {
            $pullServerMachines = Get-LabVM -ComputerName $PullServer
        }
    }
    else
    {
        $pullServerMachines = Get-LabVM -Role DSCPullServer
    }

    Copy-LabFileItem -Path $labSources\PostInstallationActivities\SetupDscClients\SetupDscClients.ps1 -ComputerName $machines

    [bool] $useSsl = Get-LabIssuingCA -WarningAction SilentlyContinue

    foreach ($machine in $machines)
    {
        Invoke-LabCommand -ActivityName 'Setup DSC Pull Clients' -ComputerName $machine -ScriptBlock {
            param
            (
                [Parameter(Mandatory)]
                [string[]]$PullServer,

                [Parameter(Mandatory)]
                [string[]]$RegistrationKey,
                [bool] $UseSsl
            )

            C:\SetupDscClients.ps1 -PullServer $PullServer -RegistrationKey $RegistrationKey -UseSsl $UseSsl
        } -ArgumentList $pullServerMachines.FQDN, $pullServerMachines.InternalNotes.DscRegistrationKey, $useSsl -PassThru
    }
}
