function Test-LabDeployment
{
    [CmdletBinding()]

    param(
        [Parameter(ParameterSetName = 'Path')]
        [string[]]$Path,

        [Parameter(ParameterSetName = 'All')]
        [string]$SampleScriptsPath,

        [Parameter(ParameterSetName = 'All')]
        [string]$Filter,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All,

        [string]$LogDirectory = [System.Environment]::GetFolderPath('MyDocuments'),

        [hashtable]$Replace = @{}
    )

	$global:AL_TestMode = 1 #this variable is set to skip the 2nd question when deleting Azure services

    if ($PSCmdlet.ParameterSetName -eq 'Path')
    {
        foreach ($p in $Path)
        {
            if (-not (Test-Path -Path $p -PathType Leaf))
            {
                Write-Error "The file '$p' could not be found"
                return
            }

            $result = Invoke-LabScript -Path $p -Replace $Replace
            $fileName = Join-Path -Path $LogDirectory -ChildPath ("{0:yyMMdd_hhmm}_$([System.IO.Path]::GetFileNameWithoutExtension($p))_Log.xml" -f (Get-Date))
            $result | Export-Clixml -Path $fileName
            $result
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'All')
    {
        if (-not (Test-Path -Path $SampleScriptsPath -PathType Container))
        {
            Write-Error "The directory '$SampleScriptsPath' could not be found"
            return
        }

        if (-not $Filter) { $Filter = '*.ps1' }
        $scripts = Get-ChildItem -Path $SampleScriptsPath -Filter $Filter -Recurse

        foreach ($script in $scripts)
        {
            $result = Invoke-LabScript -Path $script.FullName -Replace $Replace
            $fileName = Join-Path -Path $LogDirectory -ChildPath ("{0:yyMMdd_hhmm}_$([System.IO.Path]::GetFileNameWithoutExtension($script))_Log.xml" -f (Get-Date))
            $result | Export-Clixml -Path $fileName
            $result
        }
    }

	$global:AL_TestMode = 0
}
