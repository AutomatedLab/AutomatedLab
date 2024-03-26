function Update-LabSysinternalsTools
{
    [CmdletBinding()]
    param ( )

    if ($IsLinux -or $IsMacOs) { return }
    if (Get-LabConfigurationItem -Name SkipSysInternals) {return}
    #Update SysInternals suite if needed
    $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T String, DateTime

    try
    {
        #https://docs.microsoft.com/en-us/dotnet/api/system.net.securityprotocoltype?view=netcore-2.0#System_Net_SecurityProtocolType_SystemDefault
        if ($PSVersionTable.PSVersion.Major -lt 6 -and [Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12')
        {
            Write-PSFMessage -Message 'Adding support for TLS 1.2'
            [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
        }
    }
    catch
    {
        Write-PSFMessage -Level Warning -Message 'Adding TLS 1.2 to supported security protocols was unsuccessful.'
    }

    try
    {
        Write-PSFMessage -Message 'Get last check time of SysInternals suite'
        if ($IsLinux -or $IsMacOs)
        {
            $timestamps = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/Timestamps.xml'))
        }
        else
        {
            $timestamps = $type::ImportFromRegistry('Cache', 'Timestamps')
        }
        $lastChecked = $timestamps.SysInternalsUpdateLastChecked
        Write-PSFMessage -Message "Last check was '$lastChecked'."
    }
    catch
    {
        Write-PSFMessage -Message 'Last check time could not be retrieved. SysInternals suite never updated'
        $lastChecked = Get-Date -Year 1601
        $timestamps = New-Object $type
    }

    if ($lastChecked)
    {
        $lastChecked = $lastChecked.AddDays(7)
    }

    if ((Get-Date) -gt $lastChecked)
    {
        Write-PSFMessage -Message 'Last check time is more then a week ago. Check web site for update.'

        $sysInternalsUrl = Get-LabConfigurationItem -Name SysInternalsUrl
        $sysInternalsDownloadUrl = Get-LabConfigurationItem -Name SysInternalsDownloadUrl

        try
        {
            Write-PSFMessage -Message 'Web page downloaded'
            $webRequest = Invoke-WebRequest -Uri $sysInternalsURL -UseBasicParsing
            $pageDownloaded = $true
        }
        catch
        {
            Write-PSFMessage -Message 'Web page could not be downloaded'
            Write-ScreenInfo -Message "No connection to '$sysInternalsURL'. Skipping." -Type Error
            $pageDownloaded = $false
        }

        if ($pageDownloaded)
        {
            $updateStart = $webRequest.Content.IndexOf('Updated') + 'Updated:'.Length
            $updateFinish = $webRequest.Content.IndexOf('</p>', $updateStart)
            $updateStringFromWebPage = $webRequest.Content.Substring($updateStart, $updateFinish - $updateStart).Trim()

            Write-PSFMessage -Message "Update string from web page: '$updateStringFromWebPage'"

            $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T String, String
            try
            {
                if ($IsLinux -or $IsMacOs)
                {
                    $versions = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/Versions.xml'))
                }
                else
                {
                    $versions = $type::ImportFromRegistry('Cache', 'Versions')
                }
            }
            catch
            {
                $versions = New-Object $type
            }

            Write-PSFMessage -Message "Update string from registry: '$currentVersion'"

            if ($versions['SysInternals'] -ne $updateStringFromWebPage)
            {
                Write-ScreenInfo -Message 'Performing update of SysInternals suite and lab sources directory now' -Type Warning -TaskStart
                Start-Sleep -Seconds 1

                # Download Lab Sources
                $null = New-LabSourcesFolder -Force -ErrorAction SilentlyContinue

                # Download SysInternals suite

                $tempFilePath = New-TemporaryFile
                $tempFilePath | Remove-Item
                $tempFilePath = [System.IO.Path]::ChangeExtension($tempFilePath.FullName, '.zip')
                Write-PSFMessage -Message "Temp file: '$tempFilePath'"

                try
                {
                    Invoke-WebRequest -Uri $sysInternalsDownloadURL -UseBasicParsing -OutFile $tempFilePath -ErrorAction Stop
                    $fileDownloaded = Test-Path -Path $tempFilePath
                    Write-PSFMessage -Message "File '$sysInternalsDownloadURL' downloaded: $fileDownloaded"
                }
                catch
                {
                    Write-ScreenInfo -Message "File '$sysInternalsDownloadURL' could not be downloaded. Skipping." -Type Error -TaskEnd
                    $fileDownloaded = $false
                }

                if ($fileDownloaded)
                {
                    if (-not ($IsLinux -or $IsMacOs)) { Unblock-File -Path $tempFilePath }

                    #Extract files to Tools folder
                    if (-not (Test-Path -Path "$labSources\Tools"))
                    {
                        Write-PSFMessage -Message "Folder '$labSources\Tools' does not exist. Creating now."
                        New-Item -ItemType Directory -Path "$labSources\Tools" | Out-Null
                    }
                    if (-not (Test-Path -Path "$labSources\Tools\SysInternals"))
                    {
                        Write-PSFMessage -Message "Folder '$labSources\Tools\SysInternals' does not exist. Creating now."
                        New-Item -ItemType Directory -Path "$labSources\Tools\SysInternals" | Out-Null
                    }
                    else
                    {
                        Write-PSFMessage -Message "Folder '$labSources\Tools\SysInternals' exist. Removing it now and recreating it."
                        Remove-Item -Path "$labSources\Tools\SysInternals" -Recurse | Out-Null
                        New-Item -ItemType Directory -Path "$labSources\Tools\SysInternals" | Out-Null
                    }

                    Write-PSFMessage -Message 'Extracting files'
                    Microsoft.PowerShell.Archive\Expand-Archive -Path $tempFilePath -DestinationPath "$labSources\Tools\SysInternals" -Force
                    Remove-Item -Path $tempFilePath

                    #Update registry
                    $versions['SysInternals'] = $updateStringFromWebPage
                    if ($IsLinux -or $IsMacOs)
                    {
                        $versions.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/Versions.xml'))
                    }
                    else
                    {
                        $versions.ExportToRegistry('Cache', 'Versions')
                    }

                    $timestamps['SysInternalsUpdateLastChecked'] = Get-Date
                    if ($IsLinux -or $IsMacOs)
                    {
                        $timestamps.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/Timestamps.xml'))
                    }
                    else
                    {
                        $timestamps.ExportToRegistry('Cache', 'Timestamps')
                    }

                    Write-ScreenInfo -Message "SysInternals Suite has been updated and placed in '$labSources\Tools\SysInternals'" -Type Warning -TaskEnd
                }
            }
        }
    }
}
