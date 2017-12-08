function Invoke-VisualStudioBuild
{            
    param            
    (            
        [parameter(Mandatory = $false)]            
        [ValidateNotNullOrEmpty()]             
        [String] $SourceCodePath = "C:\SourceCode\Development\",            
            
        [parameter(Mandatory = $false)]            
        [ValidateNotNullOrEmpty()]             
        [String] $SolutionFile,

        [string]
        $Configuration = 'debug'
    )   
              
    # Local Variables            
    $MsBuild = Get-ChildItem -Path 'C:\Program Files', 'C:\Program Files (x86)' -Filter "*msbuild.exe" -File -Recurse -ErrorAction SilentlyContinue | 
        Where-Object FullName -like *amd64* |
        Sort-Object {$_.VersionInfo.FileVersion } -Descending | 
        Select-Object -First 1 -ExpandProperty FullName
                   
    # Local Variables            
    $SlnFilePath = Join-Path $SourceCodePath $SolutionFile

    $BuildArgs = @{            
        FilePath               = $MsBuild            
        ArgumentList           = $SlnFilePath, "/t:rebuild", ("/p:Configuration=" + $Configuration), "/v:minimal"
        Wait                   = $true
        PassThru               = $true
    }
            
    $process = Start-Process @BuildArgs     
    if ($process.ExitCode -gt 0)
    {
        throw "MSBuild error $($process.ExitCode)"
    }         
}

# PSake makes variables declared here available in other scriptblocks
# Init some things
Properties {
    # Find the build folder based on build system
    $ProjectRoot = $ENV:BHProjectPath
    if (-not $ProjectRoot)
    {
        $ProjectRoot = $PSScriptRoot
    }

    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
    $lines = '----------------------------------------------------------------------'
}

Task Default -Depends Deploy

Task Init {
    $lines
    Set-Location $ProjectRoot
    "Build System Details:"
    Get-Item ENV:BH*
    "`n"
}

Task Test -Depends Init {
    $lines
    "`n`tSTATUS: Testing with PowerShell $PSVersion"

    # Gather test results. Store them in a variable and file
    $TestResults = Invoke-Pester -Path $ProjectRoot\Tests -PassThru -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile"

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
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
    "`n"
}

Task Build -Depends Test {
    $lines
    
    # Load the module, read the exported functions, update the psd1 FunctionsToExport
    #Set-ModuleFunctions -Verbose

    # Bump the module version
    Update-Metadata -Path $env:BHPSModuleManifest -Verbose
}

Task Deploy -Depends Build {
    $lines
    "Starting deployment with files inside $ProjectRoot"

    Invoke-VisualStudioBuild -SourceCodePath $ENV:BHProjectPath -SolutionFile "$ENV:BHProjectName.sln"

    $Params = @{
        Path    = $ProjectRoot
        Force   = $true
        Recurse = $false # We keep psdeploy artifacts, avoid deploying those : )
        Verbose = $true
    }
    Invoke-PSDeploy @Params
}