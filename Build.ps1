function Resolve-Module
{
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]$Name
    )

    Process
    {
        foreach ($moduleName in $Name)
        {
            $module = Get-Module -Name $moduleName -ListAvailable
            Write-Verbose -Message "Resolving Module $($moduleName)"
            
            if ($module) 
            {                
                $version = $module | Measure-Object -Property Version -Maximum | Select-Object -ExpandProperty Maximum
                $galleryVersion = Find-Module -Name $moduleName -Repository PSGallery | Measure-Object -Property Version -Maximum | Select-Object -ExpandProperty Maximum

                if ($version -lt $galleryVersion)
                {
                    
                    if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') { Set-PSRepository -Name PSGallery -InstallationPolicy Trusted }
                    
                    Write-Verbose -Message "$($moduleName) Installed Version [$($version.ToString())] is outdated. Installing Gallery Version [$($galleryVersion.ToString())]"
                    
                    Install-Module -Name $moduleName -Force -SkipPublisherCheck -AllowClobber
                    Import-Module -Name $moduleName -Force -RequiredVersion $galleryVersion
                }
                else
                {
                    Write-Verbose -Message "Module Installed, Importing $($moduleName)"
                    Import-Module -Name $moduleName -Force -RequiredVersion $version
                }
            }
            else
            {
                Write-Verbose -Message "$($moduleName) Missing, installing Module"
                Install-Module -Name $moduleName -Force -AllowClobber
                Import-Module -Name $moduleName -Force -RequiredVersion $version
            }
        }
    }
}

# Grab nuget bits, install modules, set build variables, start build.
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

Resolve-Module -Name Psake, PSDeploy, Pester, BuildHelpers, AutomatedLab, Ships

$lastestVersion = Get-Module -Name PackageManagement -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1
if (-not ($lastestVersion.Version -ge '1.1.7.0'))
{
    Write-Host "Latest Version of 'PackageManagement' is '$($lastestVersion.Version)'. Updating to the latest version on the PowerShell Gallery"
    Install-Module -Name PackageManagement -RequiredVersion 1.1.7.0 -Force -Confirm:$false #-Verbose

    Remove-Module -Name PackageManagement -Force -ErrorAction Ignore
    $m = Import-Module -Name PackageManagement -PassThru
    Write-Host "New version of 'PackageManagement' is not $($m.Version)"
}

$lastestVersion = Get-Module -Name PowerShellGet -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1
if (-not ($lastestVersion.Version -ge '1.6.0'))
{
    Write-Host "Latest Version of 'PowerShellGet' is '$($lastestVersion.Version)'. Updating to the latest version on the PowerShell Gallery"
    Install-Module -Name PowerShellGet -RequiredVersion 1.6.0 -Force -Confirm:$false #-Verbose

    Remove-Module -Name PowerShellGet -Force -ErrorAction Ignore
    $m = Import-Module -Name PowerShellGet -PassThru
    Write-Host "New version of 'PowerShellGet' is not $($m.Version)"
    
}

Invoke-psake .\psake.ps1
exit ( [int]( -not $psake.build_success ) )