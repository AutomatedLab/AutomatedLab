function Install-LabSoftwarePackage
{
    param (
        [Parameter(Mandatory, ParameterSetName = 'SinglePackage')]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory, ParameterSetName = 'SingleLocalPackage')]
        [ValidateNotNullOrEmpty()]
        [string]$LocalPath,

        [Parameter(ParameterSetName = 'SinglePackage')]
        [Parameter(ParameterSetName = 'SingleLocalPackage')]
        [ValidateNotNullOrEmpty()]
        [string]$CommandLine,

        [int]$Timeout = 10,

        [Parameter(ParameterSetName = 'SinglePackage')]
        [Parameter(ParameterSetName = 'SingleLocalPackage')]
        [bool]$CopyFolder,

        [Parameter(Mandatory, ParameterSetName = 'SinglePackage')]
        [Parameter(Mandatory, ParameterSetName = 'SingleLocalPackage')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'MulitPackage')]
        [AutomatedLab.Machine[]]$Machine,

        [Parameter(Mandatory, ParameterSetName = 'MulitPackage')]
        [AutomatedLab.SoftwarePackage]$SoftwarePackage,

        [string]$WorkingDirectory,

        [switch]$DoNotUseCredSsp,

        [switch]$AsJob,

        [switch]$AsScheduledJob,

        [switch]$UseExplicitCredentialsForScheduledJob,

        [switch]$UseShellExecute,

        [int[]]$ExpectedReturnCodes,

        [switch]$PassThru,

        [switch]$NoDisplay,

        [int]$ProgressIndicator = 5
    )

    Write-LogFunctionEntry
    $parameterSetName = $PSCmdlet.ParameterSetName

    if ($Path -and (Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        if (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $Path)
        {
            $parameterSetName = 'SingleLocalPackage'
            $LocalPath = $Path
        }
    }

    if ($parameterSetName -eq 'SinglePackage')
    {
        if (-not (Test-Path -Path $Path))
        {
            Write-Error "The file '$Path' cannot be found. Software cannot be installed"
            return
        }

        if (Get-Command -Name Unblock-File -ErrorAction SilentlyContinue)
        {
            Unblock-File -Path $Path
        }
    }

    if ($parameterSetName -like 'Single*')
    {
        $Machine = Get-LabVM -ComputerName $ComputerName

        if (-not $Machine)
        {
            Write-Error "The machine '$ComputerName' could not be found."
            return
        }

        $unknownMachines = (Compare-Object -ReferenceObject $ComputerName -DifferenceObject $Machine.Name).InputObject
        if ($unknownMachines)
        {
            Write-ScreenInfo "The machine(s) '$($unknownMachines -join ', ')' could not be found." -Type Warning
        }

        if ($AsScheduledJob -and $UseExplicitCredentialsForScheduledJob -and
        ($Machine | Group-Object -Property DomainName).Count -gt 1)
        {
            Write-Error "If you install software in a background job and require the scheduled job to run with explicit credentials, this task can only be performed on VMs being member of the same domain."
            return
        }
    }

    if ($Path)
    {
        Write-ScreenInfo -Message "Installing software package '$Path' on machines '$($ComputerName -join ', ')' " -TaskStart
    }
    else
    {
        Write-ScreenInfo -Message "Installing software package on VM '$LocalPath' on machines '$($ComputerName -join ', ')' " -TaskStart
    }

    if ('Stopped' -in (Get-LabVMStatus $ComputerName -AsHashTable).Values)
    {
        Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewLine
        Start-LabVM -ComputerName $ComputerName -Wait -ProgressIndicator 30 -NoNewline
    }

    $jobs = @()

    $parameters = @{ }
    $parameters.Add('ComputerName', $ComputerName)
    $parameters.Add('DoNotUseCredSsp', $DoNotUseCredSsp)
    $parameters.Add('PassThru', $True)
    $parameters.Add('AsJob', $True)
    $parameters.Add('ScriptBlock', (Get-Command -Name Install-SoftwarePackage).ScriptBlock)

    if ($parameterSetName -eq 'SinglePackage')
    {
        if ($CopyFolder)
        {
            $parameters.Add('DependencyFolderPath', [System.IO.Path]::GetDirectoryName($Path))
            $dependency = Split-Path -Path ([System.IO.Path]::GetDirectoryName($Path)) -Leaf
            $installPath = Join-Path -Path (Get-LabConfigurationItem -Name OsRoot) -ChildPath "$($dependency)/$(Split-Path -Path $Path -Leaf)"
        }
        else
        {
            $parameters.Add('DependencyFolderPath', $Path)
            $installPath = Join-Path -Path (Get-LabConfigurationItem -Name OsRoot) -ChildPath (Split-Path -Path $Path -Leaf)
        }        
    }
    elseif ($parameterSetName -eq 'SingleLocalPackage')
    {
        $installPath = $LocalPath
        if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and $CopyFolder)
        {
            $parameters.Add('DependencyFolderPath', [System.IO.Path]::GetDirectoryName($Path))
        }
    }
    else
    {
        if ($SoftwarePackage.CopyFolder)
        {
            $parameters.Add('DependencyFolderPath', [System.IO.Path]::GetDirectoryName($SoftwarePackage.Path))
            $dependency = Split-Path -Path ([System.IO.Path]::GetDirectoryName($SoftwarePackage.Path)) -Leaf
            $installPath = Join-Path -Path (Get-LabConfigurationItem -Name OsRoot) -ChildPath "$($dependency)/$(Split-Path -Path $SoftwarePackage.Path -Leaf)"
        }
        else
        {
            $parameters.Add('DependencyFolderPath', $SoftwarePackage.Path)
            $installPath = Join-Path -Path (Get-LabConfigurationItem -Name OsRoot) -ChildPath $(Split-Path -Path $SoftwarePackage.Path -Leaf)
        }        
    }

    $installParams = @{
        Path = $installPath
        CommandLine = $CommandLine
    }
    if ($AsScheduledJob) { $installParams.AsScheduledJob = $true }
    if ($UseShellExecute) { $installParams.UseShellExecute = $true }
    if ($AsScheduledJob -and $UseExplicitCredentialsForScheduledJob) { $installParams.Credential = $Machine[0].GetCredential((Get-Lab)) }
    if ($ExpectedReturnCodes) { $installParams.ExpectedReturnCodes = $ExpectedReturnCodes }
    if ($WorkingDirectory) { $installParams.WorkingDirectory = $WorkingDirectory }
    if ($CopyFolder -and (Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        $child = Split-Path -Leaf -Path $parameters.DependencyFolderPath
        $installParams.DestinationPath = Join-Path -Path (Get-LabConfigurationItem -Name OsRoot) -ChildPath $child
    }

    $parameters.Add('ActivityName', "Installation of '$installPath'")

    Write-PSFMessage -Message "Starting background job for '$($parameters.ActivityName)'"

    $parameters.ScriptBlock = {
        Import-Module -Name AutomatedLab.Common -ErrorAction SilentlyContinue
        if ($installParams.Path.StartsWith('\\') -and (Test-Path /ALAzure))
        {
            # Often issues with Zone Mapping
            if ($installParams.DestinationPath)
            {
                $newPath = (New-Item -ItemType Directory -Path $installParams.DestinationPath -Force).FullName
            }
            else
            {
                $newPath = if ($IsLinux) { "/$(Split-Path -Path $installParams.Path -Leaf)" } else { "C:\$(Split-Path -Path $installParams.Path -Leaf)"}
            }

            $installParams.Remove('DestinationPath')
            Copy-Item -Path $installParams.Path -Destination $newPath -Force

            if (-not (Test-Path -Path $newPath -PathType Leaf))
            {
                $newPath = Join-Path -Path $newPath -ChildPath (Split-Path -Path $installParams.Path -Leaf)
            }
            $installParams.Path = $newPath
        }

        if ($PSEdition -eq 'core' -and $installParams.Contains('AsScheduledJob'))
        {
            # Core cannot work with PSScheduledJob module
            $xmlParameters = ([System.Management.Automation.PSSerializer]::Serialize($installParams, 2)) -replace "`r`n"
            $b64str = [Convert]::ToBase64String(([Text.Encoding]::Unicode.GetBytes("`$installParams = [System.Management.Automation.PSSerializer]::Deserialize('$xmlParameters'); Install-SoftwarePackage @installParams")))
            powershell.exe -EncodedCommand $b64str
        }
        else
        {
            Install-SoftwarePackage @installParams
        }
    }

    $parameters.Add('NoDisplay', $True)

    if (-not $AsJob)
    {
        Write-ScreenInfo -Message "Copying files and initiating setup on '$($ComputerName -join ', ')' and waiting for completion" -NoNewLine
    }

    $job = Invoke-LabCommand @parameters -Variable (Get-Variable -Name installParams) -Function (Get-Command Install-SoftwarePackage)

    if (-not $AsJob)
    {
        Write-PSFMessage "Waiting on job ID '$($job.ID -join ', ')' with name '$($job.Name -join ', ')'"
        $results = Wait-LWLabJob -Job $job -Timeout $Timeout -ProgressIndicator 15 -NoDisplay -PassThru #-ErrorAction SilentlyContinue

        Write-PSFMessage "Job ID '$($job.ID -join ', ')' with name '$($job.Name -join ', ')' finished"
    }

    if ($AsJob)
    {
        Write-ScreenInfo -Message 'Installation started in background' -TaskEnd
        if ($PassThru) { $job }
    }
    else
    {
        Write-ScreenInfo -Message 'Installation done' -TaskEnd
        if ($PassThru) { $results }
    }

    Write-LogFunctionExit
}
