function Install-LabSoftwarePackages
{
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [AutomatedLab.Machine[]]$Machine,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [AutomatedLab.SoftwarePackage[]]$SoftwarePackage,

        [switch]$WaitForInstallation,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    $start = Get-Date
    $jobs = @()

    foreach ($m in $Machine)
    {
        Write-PSFMessage -Message "Install-LabSoftwarePackages: Working on machine '$m'"
        foreach ($p in $SoftwarePackage)
        {
            Write-PSFMessage -Message "Install-LabSoftwarePackages: Building installation package for '$p'"

            $param = @{ }
            $param.Add('Path', $p.Path)
            if ($p.CommandLine)
            {
                $param.Add('CommandLine', $p.CommandLine)
            }
            $param.Add('Timeout', $p.Timeout)
            $param.Add('ComputerName', $m.Name)
            $param.Add('PassThru', $true)

            Write-PSFMessage -Message "Install-LabSoftwarePackages: Calling installation package '$p'"

            $jobs += Install-LabSoftwarePackage @param

            Write-PSFMessage -Message "Install-LabSoftwarePackages: Installation for package '$p' finished"
        }
    }

    Write-PSFMessage 'Waiting for installation jobs to finish'

    if ($WaitForInstallation)
    {
        Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -NoDisplay
    }

    $end = Get-Date

    Write-PSFMessage "Installation of all software packages took '$($end - $start)'"

    if ($PassThru)
    {
        $jobs
    }

    Write-LogFunctionExit
}
