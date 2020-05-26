function Import-LabTestResult
{
    [CmdletBinding(DefaultParameterSetName = 'Path')]

    param(
        [Parameter(ParameterSetName = 'Single')]
        [string[]]$Path,

        [Parameter(ParameterSetName = 'Path')]
        [string]$LogDirectory = [System.Environment]::GetFolderPath('MyDocuments')
    )

    if ($PSCmdlet.ParameterSetName -eq 'Single')
    {
        if (-not (Test-Path -Path $Path -PathType Leaf))
        {
            Write-Error "The file '$Path' could not be found"
            return
        }

        $result = Import-Clixml -Path $Path
        $result.PSObject.TypeNames.Insert(0, 'AutomatedLab.TestResult')
        $result
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Path')
    {
        $files = Get-Item -Path "$LogDirectory\*" -Filter *.xml

        foreach ($file in ($files | Where-Object { $_ -match $testResultPattern }))
        {
            $result = Import-Clixml -Path $file.FullName
            $result.PSObject.TypeNames.Insert(0, 'AutomatedLab.TestResult')
            $result
        }
    }
}
