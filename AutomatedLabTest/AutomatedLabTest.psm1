$testResultPattern = '\d{6}_\d{4}_([\w\(\),-]| )+_Log.xml'

#region Test-LabDeployment
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
#endregion Test-LabDeployment

#region Invoke-LabScript
function Invoke-LabScript
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        
        [hashtable]$Replace
    )

    $result = New-Object PSObject -Property ([ordered]@{
            ScriptName = Split-Path -Path $Path -Leaf
            Completed = $false
            ErrorCount = 0
            Errors = $null
            ScriptFullName = $Path
            Output = $null
            RemoveErrors = $null
    })
    $result.PSObject.TypeNames.Insert(0, 'AutomatedLab.TestResult')

    Write-Host "Invoking script '$Path'"
    Write-Host '-------------------------------------------------------------'
    try
    {
        Clear-Host
        $content = Get-Content -Path $Path -Raw
        
        foreach ($element in $Replace.GetEnumerator())
        {
            $content = $content -replace $element.Key, $element.Value
        }
        
        $content = [scriptblock]::Create($content)
        
        Invoke-Command -ScriptBlock $content -ErrorVariable invokeError
        $result.Errors = $invokeError        
        $result.Completed = $true
    }
    catch
    {
        Write-Error -Exception $_.Exception -Message "Error invoking the script '$Path': $($_.Exception.Message)"
        $result.Errors = $_
        $result.Completed = $false
    }
    finally
    {
        Start-Sleep -Seconds 1
        $result.Output = Get-ConsoleText
        $result.ErrorCount = $result.Errors.Count
        Clear-Host
        
        if (Get-Lab -ErrorAction SilentlyContinue)
        {
            Remove-Lab -Confirm:$false -ErrorVariable removeErrors
        }
        
        $result.RemoveErrors = $removeErrors
        
        Write-Host '-------------------------------------------------------------'
        Write-Host "Finished invkoing script '$Path'"

        $result
    }
}
#endregion Invoke-LabScript

#region Import-LabTestResult
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
#endregion Import-LabTestResult

<#
#test a single script with string replacement needed for Azure
$result = Test-LabDeployment -Path 'C:\Users\randr\Documents\AutomatedLab Sample Scripts\Workshop Labs\PowerShell Lab - Azure.ps1' -Replace @{ 
    '<SOME UNIQUE DATA>' = "raandree$(Get-Random)"
    '<PATH TO YOU AZURE PUBLISHING FILE>' = 'D:\LabSources\Per1-AL2-Aldi-Per2-AL1-AL3-11-14-2015-credentials.publishsettings'
    "(\`$azureDefaultLocation = ')(\w| )+(')" = '$1North Europe$3'
    '(Add-LabAzureSubscription -Path \$azurePublishingFile -DefaultLocationName \$azureDefaultLocation)' = '$1 -SubscriptionName Aldi'
}

#testa a single script
$result = Test-LabDeployment -Path 'C:\Users\raandree\Documents\AutomatedLab Sample Scripts\HyperV\Single 2012R2 Server.ps1'

#test all scripts in the HyperV folder
$result = Test-LabDeployment -SampleScriptsPath 'C:\Users\randr\Documents\AutomatedLab Sample Scripts\HyperV' -All
#>