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
        foreach ($ModuleName in $Name)
        {
            $Module = Get-Module -Name $ModuleName -ListAvailable
            Write-Verbose -Message "Resolving Module $($ModuleName)"
            
            if ($Module) 
            {                
                $Version = $Module | Measure-Object -Property Version -Maximum | Select-Object -ExpandProperty Maximum
                $GalleryVersion = Find-Module -Name $ModuleName -Repository PSGallery | Measure-Object -Property Version -Maximum | Select-Object -ExpandProperty Maximum

                if ($Version -lt $GalleryVersion)
                {
                    
                    if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') { Set-PSRepository -Name PSGallery -InstallationPolicy Trusted }
                    
                    Write-Verbose -Message "$($ModuleName) Installed Version [$($Version.tostring())] is outdated. Installing Gallery Version [$($GalleryVersion.tostring())]"
                    
                    Install-Module -Name $ModuleName -Force -SkipPublisherCheck
                    Import-Module -Name $ModuleName -Force -RequiredVersion $GalleryVersion
                }
                else
                {
                    Write-Verbose -Message "Module Installed, Importing $($ModuleName)"
                    Import-Module -Name $ModuleName -Force -RequiredVersion $Version
                }
            }
            else
            {
                Write-Verbose -Message "$($ModuleName) Missing, installing Module"
                Install-Module -Name $ModuleName -Force
                Import-Module -Name $ModuleName -Force -RequiredVersion $Version
            }
        }
    }
}

# Grab nuget bits, install modules, set build variables, start build.
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

Resolve-Module Psake, PSDeploy, Pester, BuildHelpers

Set-BuildEnvironment

Invoke-psake .\psake.ps1
exit ( [int]( -not $psake.build_success ) )
