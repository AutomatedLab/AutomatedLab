function Install-LabOffice2016
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry

    $config2016XmlTemplate = @"
<Configuration>
  <Add OfficeClientEdition="32">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Updates Enabled="TRUE" />
  <Display Level="None" AcceptEULA="TRUE" />
  <Property Name="SharedComputerLicensing" Value="{0}" />
  <Logging Level="Standard" Path="%temp%" />
  <!--Silent install of 32-Bit Office 365 ProPlus with Updates and Logging enabled-->
</Configuration>
"@

    $lab = Get-Lab
    $roleName = [AutomatedLab.Roles]::Office2016

    if (-not (Get-LabVM))
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM -Role $roleName
    if (-not $machines)
    {
        Write-LogFunctionExitWithError -Message "There is no machine with the role $roleName"
        return
    }

    $isoImage = $lab.Sources.ISOs | Where-Object { $_.Name -eq $roleName }
    if (-not $isoImage)
    {
        Write-LogFunctionExitWithError -Message "There is no ISO image available to install the role '$roleName'. Please add the required ISO to the lab and name it '$roleName'"
        return
    }

    $officeDeploymentToolFileName = 'OfficeDeploymentTool.exe'
    $officeDeploymentToolFilePath = Join-Path -Path $labSources\SoftwarePackages -ChildPath $officeDeploymentToolFileName
    $officeDeploymentToolUri = Get-LabConfigurationItem -Name OfficeDeploymentTool

    if (-not (Test-Path -Path $officeDeploymentToolFilePath))
    {
        Get-LabInternetFile -Uri $officeDeploymentToolUri -Path $officeDeploymentToolFilePath
    }

    Write-ScreenInfo -Message 'Waiting for machines to startup' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 15

    $jobs = @()

    foreach ($machine in $machines)
    {
        $sharedComputerLicense = $false
        $officeRole = $machine.Roles | Where-Object Name -eq 'Office2016'
        $sharedComputerLicense = [int]($officeRole.Properties.SharedComputerLicensing)
        $config2016Xml = $config2016XmlTemplate -f $sharedComputerLicense

        Write-ScreenInfo "Preparing Office 2016 installation on '$machine'..." -NoNewLine
        $disk = Mount-LabIsoImage -ComputerName $machine -IsoPath $isoImage.Path -PassThru -SupressOutput

        Invoke-LabCommand -ActivityName 'Copy Office to C' -ComputerName $machine -ScriptBlock {
            New-Item -ItemType Directory -Path C:\Office | Out-Null
            Copy-Item -Path "$($args[0])\Office" -Destination C:\Office -Recurse
        } -ArgumentList $disk.DriveLetter

        Install-LabSoftwarePackage -Path $officeDeploymentToolFilePath -CommandLine '/extract:c:\Office /quiet' -ComputerName $machine -NoDisplay

        $tempFile = (Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'Configuration.xml')

        $config2016Xml | Out-File -FilePath $tempFile -Force
        Copy-LabFileItem -Path $tempFile -ComputerName $machine -DestinationFolderPath /Office

        Remove-Item -Path $tempFile

        Dismount-LabIsoImage -ComputerName $machine -SupressOutput
        Write-ScreenInfo 'finished.'
    }

    $jobs = Install-LabSoftwarePackage -LocalPath C:\Office\setup.exe -CommandLine '/configure c:\Office\Configuration.xml' -ComputerName $machines -AsJob -PassThru

    Write-ScreenInfo -Message 'Waiting for Office 2016 to complete installation' -NoNewline

    Wait-LWLabJob -Job $jobs -ProgressIndicator 15 -Timeout 30 -NoDisplay

    Write-LogFunctionExit
}
