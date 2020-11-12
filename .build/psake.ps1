# PSake makes variables declared here available in other scriptblocks
# Init some things
Properties {
    $ProjectRoot = $env:APPVEYOR_BUILD_FOLDER
    $Timestamp = Get-Date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
    $lines = '----------------------------------------------------------------------'
}

Task Default -Depends BuildDebianPackage

Task Init {
    $lines
    Set-Location $ProjectRoot
    "`n"
}

Task BuildDebianPackage -Depends Test {
    if (-not $IsLinux)
    {
        return 
    }

    # Build debian package structure
    $null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/local/share/powershell/Modules -Force
    $null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/share/AutomatedLab/Assets -Force
    $null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/share/AutomatedLab/Stores -Force
    $null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/share/AutomatedLab/Labs -Force
    $null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/share/AutomatedLab/LabSources -Force
    $null = New-Item -ItemType Directory -Path ./deb/automatedlab/DEBIAN -Force

    # Create control file
    @"
Package: automatedlab
Version: $env:APPVEYOR_BUILD_VERSION
Maintainer: https://automatedlab.org
Description: Installs the pwsh module AutomatedLab in the global module directory
Section: utils
Architecture: amd64
Bugs: https://github.com/automatedlab/automatedlab/issues
Homepage: https://automatedlab.org
Pre-Depends: powershell
Installed-Size: $('{0:0}' -f ((Get-ChildItem -Path $env:APPVEYOR_BUILD_FOLDER -Exclude .git -File -Recurse | Measure-Object Length -Sum).Sum /1mb))
"@ | Set-Content -Path ./deb/automatedlab/DEBIAN/control -Encoding UTF8

    # Copy content
    foreach ($source in [IO.DirectoryInfo[]]@('./AutomatedLab', './AutomatedLab.Recipe', './AutomatedLab.Ships', './AutomatedLabDefinition', './AutomatedLabNotifications', './AutomatedLabTest', './AutomatedLabUnattended', './AutomatedLabWorker', './HostsFile', './PSLog', './PSFileTransfer'))
    {
        $sourcePath = Join-Path -Path $source -ChildPath '/*'
        $modulepath = Join-Path -Path ./deb/automatedlab/usr/local/share/powershell/Modules -ChildPath "$($source.Name)/$($env:APPVEYOR_BUILD_VERSION)"
        $null = New-Item -ItemType Directory -Path $modulePath -Force
        Copy-Item -Path $sourcePath -Destination $modulePath -Force -Recurse
    }

    Save-Module -Name AutomatedLab.Common, newtonsoft.json, Ships, PSFramework, xPSDesiredStateConfiguration, xDscDiagnostics, xWebAdministration -Path ./deb/automatedlab/usr/local/share/powershell/Modules

    # Pre-configure LabSources for the user
    $confPath = "./deb/automatedlab/usr/local/share/powershell/Modules/AutomatedLab/$($env:APPVEYOR_BUILD_VERSION)/AutomatedLab.init.ps1"
    Add-Content -Path $confPath -Value 'Set-PSFConfig -Module AutomatedLab -Name LabSourcesLocation -Description "Location of lab sources folder" -Validation string -Value "/usr/share/AutomatedLab/LabSources"'

    Copy-Item -Path ./Assets/* -Recurse -Destination ./deb/automatedlab/usr/share/AutomatedLab/Assets -Force
    Copy-Item -Path ./LabSources/* -Recurse -Destination ./deb/automatedlab/usr/share/AutomatedLab/LabSources -Force

    # Update permissions on AL folder to allow non-root access to configs
    chmod -R 775 ./deb/automatedlab/usr/share/AutomatedLab

    # Build debian package and convert it to RPM
    dpkg-deb --build ./deb/automatedlab automatedlab_NONSTABLEBETA_$($env:APPVEYOR_BUILD_VERSION)_x86_64.deb
    sudo alien -r automatedlab_NONSTABLEBETA_$($env:APPVEYOR_BUILD_VERSION)_x86_64.deb
    Rename-Item -Path "*.rpm" -NewName automatedlab_NONSTABLEBETA_$($env:APPVEYOR_BUILD_VERSION)_x86_64.rpm
}

Task Test -Depends Init {
    $lines
    "`n`tSTATUS: Testing with PowerShell $PSVersion"

    # Ensure recent Pester version is actually used
    if (-not $IsLinux)
    {
        Import-Module -Name Pester -MinimumVersion 5.0.0 -Force

        # Gather test results. Store them in a variable and file
        $TestResults = Invoke-Pester -Path $ProjectRoot\Tests | ConvertTo-NUnitReport -ErrorAction SilentlyContinue
        $TestResults.Save("$ProjectRoot\$TestFile")

        # In Appveyor?  Upload our tests! #Abstract this into a function?
        If ($ENV:BHBuildSystem -eq 'AppVeyor')
        {
            (New-Object 'System.Net.WebClient').UploadFile(
                "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
                "$ProjectRoot\$TestFile" )
        }

        Remove-Item "$ProjectRoot\$TestFile" -Force -ErrorAction SilentlyContinue

        # Failed tests?
        # Need to tell psake or it will proceed to the deployment. Danger!
        if ($TestResults.FailedCount -gt 0)
        {
            throw "Failed '$($TestResults.FailedCount)' tests, build failed"
        }
    }
    "`n"
}
