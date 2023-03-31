function Enter-LabPSSession
{
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0)]
        [string]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByMachine', Position = 0)]
        [AutomatedLab.Machine]$Machine,

        [switch]$DoNotUseCredSsp,

        [switch]$UseLocalCredential
    )

    if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        $Machine = Get-LabVM -ComputerName $ComputerName -IncludeLinux
    }

    if ($Machine)
    {
        $session = New-LabPSSession -Machine $Machine -DoNotUseCredSsp:$DoNotUseCredSsp -UseLocalCredential:$UseLocalCredential

        $session | Enter-PSSession
    }
    else
    {
        Write-Error 'The specified machine could not be found in the lab.'
    }
}
