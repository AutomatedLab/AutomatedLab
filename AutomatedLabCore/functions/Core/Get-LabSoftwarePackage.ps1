function Get-LabSoftwarePackage
{
    param (
        [Parameter(Mandatory)]
        [ValidateScript({
                    Test-Path -Path $_
                }
        )]
        [string]$Path,

        [string]$CommandLine,

        [int]$Timeout = 10
    )

    Write-LogFunctionEntry

    $pack = New-Object -TypeName AutomatedLab.SoftwarePackage
    $pack.CommandLine = $CommandLine
    $pack.CopyFolder = $CopyFolder
    $pack.Path = $Path
    $pack.Timeout = $timeout

    $pack

    Write-LogFunctionExit
}
