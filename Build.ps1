﻿function Resolve-Module
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

Resolve-Module -Name Psake, PSDeploy, Pester, BuildHelpers, AutomatedLab

Invoke-psake .\psake.ps1
exit ( [int]( -not $psake.build_success ) )