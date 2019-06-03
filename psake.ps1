# PSake makes variables declared here available in other scriptblocks
# Init some things
Properties {
    $ProjectRoot = $PSScriptRoot
    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
    $lines = '----------------------------------------------------------------------'
}

Task Default -Depends Test

Task Init {
    $lines
    Set-Location $ProjectRoot
    "`n"
}

Task BuildHelpContent -Depends Init {
    $lines
    "`n`tSTATUS: Compiling help content from markdown"
    foreach ($language in (Get-ChildItem -Path (Join-Path $ProjectRoot -ChildPath Help) -Directory))
    {
        $ci = try { [cultureinfo]$language.BaseName} catch { }
        if (-not $ci) {continue}

        New-ExternalHelp -Path $language.FullName -OutputPath (Join-Path $ProjectRoot -ChildPath "$ENV:BHProjectName\$($language.BaseName)")
    }
}

Task Test -Depends Init {
    $lines
    "`n`tSTATUS: Testing with PowerShell $PSVersion"

    # Ensure recent Pester version is actually used
    Import-Module -Name Pester -MinimumVersion 4.0.0 -Force

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
        throw "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
    "`n"
}
