function Install-LabOffice2013
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry
    $lab = Get-Lab
    $roleName = [AutomatedLab.Roles]::Office2013

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

    Write-ScreenInfo -Message 'Waiting for machines to startup' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 15

    Mount-LabIsoImage -ComputerName $machines -IsoPath $isoImage.Path -SupressOutput

    $jobs = @()

    foreach ($machine in $machines)
    {

        $parameters = @{ }
        $parameters.Add('ComputerName', $machine.Name)
        $parameters.Add('ActivityName', 'InstallationOffice2013')
        $parameters.Add('Verbose', $VerbosePreference)
        $parameters.Add('Scriptblock', {
                $timeout = 30

                Write-Verbose 'Installing Office 2013...'

                #region Office Installation Config
                $officeInstallationConfig = @'
<Configuration Product="ProPlusr">
<Display Level="basic" CompletionNotice="no" SuppressModal="yes" AcceptEula="yes" />
<AddLanguage Id="en-us" ShellTransform="yes"/>
<Logging Type="standard" Path="C:\" Template="Microsoft Office Professional Plus Setup(*).txt" />
<USERNAME Value="blah" />
<COMPANYNAME Value="blah" />
<!-- <PIDKEY Value="Office product key with no hyphen" /> -->
<!-- <INSTALLLOCATION Value="%programfiles%\Microsoft Office" /> -->
<!-- <LIS CACHEACTION="CacheOnly" /> -->
<!-- <LIS SOURCELIST="\\server1\share\Office;\\server2\share\Office" /> -->
<!-- <DistributionPoint Location="\\server\share\Office" /> -->
<!--Access-->
<OptionState Id="ACCESSFiles" State="local" Children="force" />

<!--Excel-->
<OptionState Id="EXCELFiles" State="local" Children="force" />

<!--InfoPath-->
<OptionState Id="XDOCSFiles" State="local" Children="force" />

<!--Lync-->
<OptionState Id="LyncCoreFiles" State="absent" Children="force" />

<!--OneNote-->
<OptionState Id="OneNoteFiles" State="local" Children="force" />

<!--Outlook-->
<OptionState Id="OUTLOOKFiles" State="local" Children="force" />

<!--PowerPoint-->
<OptionState Id="PPTFiles" State="local" Children="force" />

<!--Publisher-->
<OptionState Id="PubPrimary" State="absent" Children="force" />

<!--SkyDrive Pro-->
<OptionState Id="GrooveFiles2" State="local" Children="force" />

<!--Visio Viewer-->
<OptionState Id="VisioPreviewerFiles" State="absent" Children="force" />

<!--Word-->
<OptionState Id="WORDFiles" State="local" Children="force" />

<!--Shared Files-->
<OptionState Id="SHAREDFiles" State="local" Children="force" />

<!--Tools-->
<OptionState Id="TOOLSFiles" State="local" Children="force" />

<Setting Id="SETUP_REBOOT" Value="never" />
<!-- <Command Path="%windir%\system32\msiexec.exe" Args="/i \\server\share\my.msi" QuietArg="/q" ChainPosition="after" Execute="install" /> -->
</Configuration>
'@
                #endregion Office Installation Config

                $officeInstallationConfig | Out-File -FilePath C:\Office2013Config.xml

                $start = Get-Date

                Push-Location
                Set-Location -Path (Get-WmiObject -Class Win32_CDRomDrive).Drive
                Write-Verbose 'Calling "$($PWD.Path)setup.exe /config C:\Office2013Config.xml"'
                .\setup.exe /config C:\Office2013Config.xml
                Pop-Location

                Start-Sleep -Seconds 5

                while (Get-Process -Name setup -ErrorAction SilentlyContinue)
                {
                    if ((Get-Date).AddMinutes(- $timeout) -gt $start)
                    {
                        Write-LogError -Message "Installation of 'Office 2013' hit the timeout of $Timeout minutes. Killing the setup process"

                        Get-Process -Name setup | Stop-Process -Force

                        Write-Error -Message 'Installation of Office 2013 was not successfull'
                        return
                    }

                    Start-Sleep -Seconds 5
                }


                Write-Verbose '...Installation seems to be done'
            }
        )

        $jobs += Invoke-LabCommand @parameters -asjob -PassThru -NoDisplay
    }

    Write-ScreenInfo -Message 'Waiting for Office 2013 to complete installation' -NoNewline

    Wait-LWLabJob -Job $jobs -ProgressIndicator 15 -Timeout 30 -NoDisplay

    Dismount-LabIsoImage -ComputerName $machines -SupressOutput

    Write-LogFunctionExit
}
