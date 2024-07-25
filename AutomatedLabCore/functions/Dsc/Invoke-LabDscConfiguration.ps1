function Invoke-LabDscConfiguration
{
    [CmdletBinding(DefaultParameterSetName = 'New')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'New')]
        [System.Management.Automation.ConfigurationInfo]$Configuration,

        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        
        [Parameter()]
        [hashtable]$Parameter,

        [Parameter(ParameterSetName = 'New')]
        [hashtable]$ConfigurationData,

        [Parameter(ParameterSetName = 'UseExisting')]
        [switch]$UseExisting,

        [switch]$Wait,

        [switch]$Force
    )

    Write-LogFunctionEntry

    $lab = Get-Lab
    $localLabSoures = Get-LabSourcesLocation -Local
    if (-not $lab.Machines)
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM -ComputerName $ComputerName
    if ($machines.Count -ne $ComputerName.Count)
    {
        Write-Error -Message 'Not all machines specified could be found in the lab.'
        Write-LogFunctionExit
        return
    }

    if ($PSCmdlet.ParameterSetName -eq 'New')
    {
        $outputPath = "$localLabSoures\$(Get-LabConfigurationItem -Name DscMofPath)\$(New-Guid)"

        if (Test-Path -Path $outputPath)
        {
            Remove-Item -Path $outputPath -Recurse -Force
        }
        New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

        if ($ConfigurationData)
        {
            $result = ValidateUpdate-ConfigurationData -ConfigurationData $ConfigurationData
            if (-not $result)
            {
                return
            }
        }

        $mofTempPath = [System.IO.Path]::GetTempFileName()
        $metaMofTempPath = [System.IO.Path]::GetTempFileName()
        Remove-Item -Path $mofTempPath
        Remove-Item -Path $metaMofTempPath
        New-Item -ItemType Directory -Path $mofTempPath | Out-Null
        New-Item -ItemType Directory -Path $metaMofTempPath | Out-Null

        $dscModules = @()

        $null = foreach ($c in $ComputerName)
        {
            if ($ConfigurationData)
            {
                $adaptedConfig = $ConfigurationData.Clone()
            }

            Push-Location -Path Function:
            if ($configuration | Get-Item -ErrorAction SilentlyContinue)
            {
                $configuration | Remove-Item
            }
            $configuration | New-Item -Force
            Pop-Location

            Write-Information -MessageData "Creating Configuration MOF '$($Configuration.Name)' for node '$c'" -Tags DSC
            
            $param = @{
                OutputPath = $tempPath
                WarningAction = 'SilentlyContinue'
            }
            if ($Configuration.Parameters.ContainsKey('ComputerName'))
            {
                $param.ComputerName = $c
            }
            if ($adaptedConfig)
            {
                $param.ConfigurationData = $adaptedConfig
            }
            
            if ($Parameter)
            {
                $param += $Parameter
            }
            
            $mofs = & $Configuration.Name @param
            
            $mof = $mofs | Where-Object { $_.Name -like "*$c*" -and $_.Name -notlike '*.meta.mof' }
            $metaMof = $mofs | Where-Object { $_.Name -like "*$c*" -and $_.Name -like '*.meta.mof' }

            if ($null -ne $mof)
            {
                $mof = $mof | Rename-Item -NewName "$($Configuration.Name)_$c.mof" -Force -PassThru
                $mof | Move-Item -Destination $outputPath -Force
                Remove-Item -Path $mofTempPath -Force -Recurse
            }
            if ($null -ne $metaMof)
            {
                $metaMof = $metaMof | Rename-Item -NewName "$($Configuration.Name)_$c.meta.mof" -Force -PassThru
                $metaMof | Move-Item -Destination $outputPath -Force
                Remove-Item -Path $metaMofTempPath -Force -Recurse
            }
        }

        $mofFiles = Get-ChildItem -Path $outputPath -Filter *.mof | Where-Object Name -Match '(?<ConfigurationName>\w+)_(?<ComputerName>[\w-_]+)\.mof'
        foreach ($c in $ComputerName)
        {
            foreach ($mofFile in $mofFiles)
            {
                if ($mofFile.Name -match "(?<ConfigurationName>$($Configuration.Name))_(?<ComputerName>$c)\.mof")
                {
                    Send-File -Source $mofFile.FullName -Session (New-LabPSSession -ComputerName $Matches.ComputerName) -Destination "C:\AL Dsc\$($Configuration.Name)" -Force
                }
            }
        }

        $metaMofFiles = Get-ChildItem -Path $outputPath -Filter *.mof | Where-Object Name -Match '(?<ConfigurationName>\w+)_(?<ComputerName>[\w-_]+)\.meta.mof'
        foreach ($c in $ComputerName)
        {
            foreach ($metaMofFile in $metaMofFiles)
            {
                if ($metaMofFile.Name -match "(?<ConfigurationName>$($Configuration.Name))_(?<ComputerName>$c)\.meta.mof")
                {
                    Send-File -Source $metaMofFile.FullName -Session (New-LabPSSession -ComputerName $Matches.ComputerName) -Destination "C:\AL Dsc\$($Configuration.Name)" -Force
                }
            }
        }

        #Get-DscConfigurationImportedResource now needs to walk over all the resources used in the composite resource
        #to find out all the reuqired modules we need to upload in total
        $requiredDscModules = Get-DscConfigurationImportedResource -Configuration $Configuration -ErrorAction Stop
        foreach ($requiredDscModule in $requiredDscModules)
        {
            Send-ModuleToPSSession -Module (Get-Module -Name $requiredDscModule -ListAvailable) -Session (New-LabPSSession -ComputerName $ComputerName) -Scope AllUsers -IncludeDependencies
        }

        Invoke-LabCommand -ComputerName $ComputerName -ActivityName 'Applying new DSC configuration' -ScriptBlock {

            $path = "C:\AL Dsc\$($Configuration.Name)"

            Remove-Item -Path "$path\localhost.mof" -ErrorAction SilentlyContinue
            Remove-Item -Path "$path\localhost.meta.mof" -ErrorAction SilentlyContinue

            $mofFiles = Get-ChildItem -Path $path -Filter *.mof | Where-Object Name -notlike *.meta.mof
            if ($mofFiles.Count -gt 1)
            {
                throw "There is more than one MOF file in the folder '$path'. Expected is only one file."
            }

            $metaMofFiles = Get-ChildItem -Path $path -Filter *.mof | Where-Object Name -like *.meta.mof
            if ($metaMofFiles.Count -gt 1)
            {
                throw "There is more than one Meta MOF file in the folder '$path'. Expected is only one file."
            }

            if ($null -ne $metaMofFiles)
            {
                $metaMofFiles | Rename-Item -NewName localhost.meta.mof
                Set-DscLocalConfigurationManager -Path $path -Force:$Force
            }

            if ($null -ne $mofFiles)
            {
                $mofFiles | Rename-Item -NewName localhost.mof
                Start-DscConfiguration -Path $path -Wait:$Wait -Force:$Force
            }

        } -Variable (Get-Variable -Name Configuration, Wait, Force)
    }
    else
    {
        Invoke-LabCommand -ComputerName $ComputerName -ActivityName 'Applying existing DSC configuration' -ScriptBlock {

            Start-DscConfiguration -UseExisting -Wait:$Wait -Force:$Force

        } -Variable (Get-Variable -Name Wait, Force)
    }

    Remove-Item -Path $outputPath -Recurse -Force

    Write-LogFunctionExit
}
