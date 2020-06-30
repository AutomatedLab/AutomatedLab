param
(
    [Parameter(Mandatory)]
    [string]
    $ComputerName,

    [Parameter(Mandatory)]
    [string]$IsoPath

)

$config2019Xml = @"
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

$lab = Import-Lab -Name $data.Name -NoValidation -NoDisplay -PassThru
$labMachine = Get-LabVm -ComputerName $ComputerName

if (-not $lab)
{
    Write-Error -Message 'Please deploy a lab first.'
    return
}

if ($Lab.DefaultVirtualizationEngine -eq 'HyperV' -and -not (Test-Path -Path $IsoPath))
{
    Write-Error "The ISO file '$IsoPath' could not be found."
    return
}

$officeDeploymentToolFileName = 'OfficeDeploymentTool.exe'
$officeDeploymentToolFilePath = Join-Path -Path $labSources\SoftwarePackages -ChildPath $officeDeploymentToolFileName
$officeDeploymentToolUri = Get-LabConfigurationItem -Name OfficeDeploymentTool

Get-LabInternetFile -Uri $officeDeploymentToolUri -Path $officeDeploymentToolFilePath


Write-ScreenInfo -Message 'Waiting for machines to startup' -NoNewline
Start-LabVM -ComputerName $ComputerName -Wait -ProgressIndicator 15

Write-ScreenInfo "Preparing Office 2019 installation on '$ComputerName'..." -NoNewLine
$disk = Mount-LabIsoImage -ComputerName $ComputerName -IsoPath $IsoPath -PassThru -SupressOutput

Invoke-LabCommand -ActivityName 'Copy Office to C' -ComputerName $ComputerName -ScriptBlock {
New-Item -ItemType Directory -Path C:\Office | Out-Null
Copy-Item -Path "$($args[0])\Office" -Destination C:\Office -Recurse
} -ArgumentList $disk.DriveLetter -passthru

Install-LabSoftwarePackage -Path $officeDeploymentToolFilePath -CommandLine '/extract:c:\Office /quiet' -ComputerName $ComputerName -NoDisplay

$tempFile = (Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'Configuration.xml')

$config2019Xml | Out-File -FilePath $tempFile -Force
Copy-LabFileItem -Path $tempFile -ComputerName $ComputerName -DestinationFolderPath /Office

Remove-Item -Path $tempFile
Dismount-LabIsoImage -ComputerName $ComputerName -SupressOutput
Write-ScreenInfo 'finished.'

$jobs = @()

$jobs = Install-LabSoftwarePackage -LocalPath C:\Office\setup.exe -CommandLine '/configure c:\Office\Configuration.xml' -ComputerName $ComputerName -AsJob -PassThru -Timeout 15

Write-ScreenInfo -Message 'Waiting for Office 2019 to complete installation' -NoNewline

Wait-LWLabJob -Job $jobs -ProgressIndicator 15 -Timeout 30 -NoDisplay

Write-ScreenInfo "Finished installing Office 2019 on $ComputerName " -TaskEnd