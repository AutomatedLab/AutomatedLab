#region Get-LabHyperVAvailableMemory
function Get-LabHyperVAvailableMemory
{
    # .ExternalHelp AutomatedLab.Help.xml
    [int](((Get-WmiObject -Namespace Root\Cimv2 -Class win32_operatingsystem).TotalVisibleMemorySize) / 1kb)
}
#endregion Get-LabHyperVAvailableMemory

#region Reset-AutomatedLab
function Reset-AutomatedLab
{
    # .ExternalHelp AutomatedLab.Help.xml
    Remove-Lab
    Remove-Module *
}
#endregion Reset-AutomatedLab

#region Save-Hashes
function Save-Hashes
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        $Filename = 'C:\ALFiles.txt',
        $FolderName
    )

    $ModulePath = "$([environment]::getfolderpath('mydocuments'))\WindowsPowerShell\Modules"
    $Folders = 'AutomatedLab', 'AutomatedLabDefinition', 'AutomatedLabUnattended', 'AutomatedLabWorker', 'HostsFile', 'PSFileTransfer', 'PSLog'

    foreach ($Folder in $Folders)
    {
        Get-FileHash -Path "$ModulePath\$Folder\*" | Select-Object Algorithm, Hash, @{name='Path';expression={$_.Path.Replace($ModulePath, '<MODULEPATH>')}} | Export-Csv -Path $Filename -Append
    }

    if ($FolderName)
    {
        foreach ($Folder in $Foldername)
        {
            Get-ChildItem -Path C:\LabSources\Tools\PSv4Part1 -Recurse -Exclude '*.ISO' | Get-FileHash | Export-Csv -Path $Filename -Append
        }
    }
}
#endregion Save-Hashes

#region Test-FileHashes
function Test-FileHashes
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        $Filename = 'C:\ALFiles.txt'
    )

    $ModulePath = "$([environment]::getfolderpath('mydocuments'))\WindowsPowerShell\Modules"

    $StoredHashes = Import-Csv -Path $Filename

    $Issues = $False
    foreach ($File in $StoredHashes)
    {
        if (-not (Test-Path $File.path.replace('<MODULEPATH>', $ModulePath)))
        {
            "'$File' is missing"
            $Issues = $True
        }
        else
        {
            if ((Get-FileHash -Path $File.path.replace('<MODULEPATH>', $ModulePath)).hash -ne $File.Hash)
            {
                "'$File.Path' has wrong hash and is thereby not the file you think it is"
                $Issues = $True
            }
        }
    }

    $Issues
}
#endregion Test-FileHashes

#region Save-FileList
function Save-FileList
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        $Filename = 'C:\ALfiles.txt'
    )

    Get-ChildItem $ModulePath -Recurse -Directory -Include 'AutomatedLab', 'AutomatedLabDefinition', 'AutomatedLabUnattended', 'AutomatedLabWorker', 'HostsFile', 'PSFileTransfer', 'PSLog' | % {Get-ChildItem $_.FullName | Select-Object FullName} | Export-Csv -Path $Filename
}
#endregion Save-FileList

#region Test-FileList
function Test-FileList
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        $Filename = 'C:\ALfiles.txt'
    )

    $StoredFiles = Import-Csv -Path $Filename
    $Files = Get-ChildItem $ModulePath -Recurse -Directory -Include 'AutomatedLab', 'AutomatedLabDefinition', 'AutomatedLabUnattended', 'AutomatedLabWorker', 'HostsFile', 'PSFileTransfer', 'PSLog' | % {Get-ChildItem $_.FullName | Select-Object FullName}

    if (Compare-Object -ReferenceObject $StoredFiles -DifferenceObject $Files)
    {
        $true
    }
    else
    {
        $false
    }
}
#endregion Test-FileList

#region Test-FolderExist
function Test-FolderExist
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        $FolderName
    )

    if (-not (Test-Path -Path $FolderName))
    {
        throw "The folder '$FolderName' is missing or is at the wrong level. This folder is required for setting up this lab"
    }
}
#endregion Test-FolderExist

#region Test-FolderNotExist
function Test-FolderNotExist
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        $FolderName
    )

    if (Test-Path -Path $FolderName)
    {
        throw "The folder '$FolderName' exist while it should NOT exist"
    }
}
#endregion Test-FolderNotExist

#region Restart-ServiceResilient
function Restart-ServiceResilient
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        [string[]]$ComputerName,
        $ServiceName,
        [switch]$NoNewLine
    )

    Write-LogFunctionEntry

    $jobs = Invoke-LabCommand -ComputerName $ComputerName -AsJob -PassThru -NoDisplay -ActivityName "Restart service '$ServiceName' on computers '$($ComputerName -join ', ')'" -ScriptBlock `
    {
        param
        (
            [string]$ServiceName
        )

        function Get-ServiceRestartInfo
        {
            param
            (
                [string]$ServiceName,
                [switch]$WasStopped,
                [switch]$WasStarted,
                [double]$Index
            )

            $serviceDisplayName = (Get-Service $ServiceName).DisplayName

            $newestEvent = "($((Get-EventLog -LogName System -newest 1).Index)) " + (Get-EventLog -LogName System -newest 1).Message
            Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Get-ServiceRestartInfo - ServiceName: $ServiceName ($serviceDisplayName) - WasStopped: $WasStopped - WasStarted:$WasStarted - Index: $Index - Newest event: $newestEvent"


            $result = $true

            if ($WasStopped)
            {
                $events = @(Get-EventLog -LogName System -Index ($Index..($Index+10000)) | Where-Object {$_.Message -like "*$serviceDisplayName*entered*stopped*"})
                Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Events found: $($events.count)"
                $result = ($events.count -gt 0)
            }
            if ($WasStarted)
            {
                $events = @(Get-EventLog -LogName System -Index ($Index..($Index+10000)) | Where-Object {$_.Message -like "*$serviceDisplayName*entered*running*"})
                Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Events found: $($events.count)"
                $result = ($events.count -gt 0)
            }

            Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Result:$result"
            $result
        }


        $BackupVerbosePreference = $VerbosePreference
        $BackupDebugPreference   = $DebugPreference
        $VerbosePreference = 'Continue'
        $DebugPreference   = 'Continue'

        $ServiceName = 'nlasvc'

        $dependentServices = Get-Service -Name $ServiceName -DependentServices | Where-Object {$_.Status -eq 'Running'} | Select-Object -ExpandProperty Name
        Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Dependent services: '$($dependentServices -join ',')'"


        $serviceDisplayName = (Get-Service $ServiceName).DisplayName
        if ((Get-Service -Name "$ServiceName").Status -eq 'Running')
        {
            $newestEventLogIndex = (Get-EventLog -LogName System -Newest 1).Index
            $retries = 5
            do
            {
                Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Trying to stop service '$ServiceName'"
                $EAPbackup = $ErrorActionPreference
                $WAPbackup = $WarningPreference

                $ErrorActionPreference = 'SilentlyContinue'
                $WarningPreference     = 'SilentlyContinue'
                Stop-Service -Name $ServiceName -Force
                $ErrorActionPreference = $EAPbackup
                $WarningPreference = $WAPbackup

                $retries--
                Start-Sleep -Seconds 1
            }
            until ((Get-ServiceRestartInfo -ServiceName $ServiceName -WasStopped -Index $newestEventLogIndex) -or $retries -le 0)
        }

        if ($retries -gt 0)
        {
            Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Service '$ServiceName' has been stopped"
        }
        else
        {
            Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Service '$ServiceName' could NOT be stopped"
            return
        }


        if (-not (Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex))
        {
            #if service did not start by itself
            $newestEventLogIndex = (Get-EventLog -LogName System -Newest 1).Index
            $retries = 5
            do
            {
                Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Trying to start service '$ServiceName'"
                Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
                $retries--
                if (-not (Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex))
                {
                    Start-Sleep -Seconds 1
                }
            }
            until ((Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex) -or $retries -le 0)
        }


        if ($retries -gt 0)
        {
            Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Service '$ServiceName' was started"
        }
        else
        {
            Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Service '$ServiceName' could NOT be started"
            return
        }

        foreach ($dependentService in $dependentServices)
        {
            if (Get-ServiceRestartInfo -ServiceName $dependentService -WasStarted -Index $newestEventLogIndex)
            {
                Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Dependent service '$dependentService' has already auto-started"
            }
            else
            {
                $newestEventLogIndex = (Get-EventLog -LogName System -Newest 1).Index
                $retries = 5
                do
                {
                    Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Trying to start depending service '$dependentService'"
                    Start-Service $dependentService -ErrorAction SilentlyContinue
                    $retries--
                }
                until ((Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex) -or $retries -le 0)

                if (Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex)
                {
                    Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Dependent service '$ServiceName' was started"
                }
                else
                {
                    Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Dependent service '$ServiceName' could NOT be started"
                }
            }
        }

        $VerbosePreference = $BackupVerbosePreference
        $DebugPreference   = $BackupDebugPreference
    } -ArgumentList $ServiceName

    Wait-LWLabJob -Job $jobs -NoDisplay -Timeout 30 -NoNewLine:$NoNewLine

    Write-LogFunctionExit
}
#endregion Restart-ServiceResilient

#region Remove-DeploymentFiles
function Remove-DeploymentFiles
{
    # .ExternalHelp AutomatedLab.Help.xml
    Invoke-LabCommand -ComputerName (Get-LabVM) -ActivityName 'Remove deployment files (files used during deployment)' -AsJob -NoDisplay -ScriptBlock `
    {
        Remove-Item -Path C:\unattend.xml
        Remove-Item -Path C:\WSManRegKey.reg
        Remove-Item -Path C:\AdditionalDisksOnline.ps1
        Remove-Item -Path C:\DeployDebug -Recurse
    }
}
#endregion Remove-DeploymentFiles

#region Enable-LabVMFirewallGroup
function Enable-LabVMFirewallGroup
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [string[]]$FirewallGroup
    )

    Write-LogFunctionEntry

    $machine = Get-LabVM -ComputerName $ComputerName

    Invoke-LabCommand -ComputerName $machine -ActivityName 'Enable firewall group' -NoDisplay -ScriptBlock `
    {
        param
        (
            [string]$FirewallGroup
        )

        $FirewallGroups = $FirewallGroup.Split(';')

        foreach ($group in $FirewallGroups)
        {
            Write-Verbose -Message "Enable firewall group '$group' on '$(hostname)'"
            netsh.exe advfirewall firewall set rule group="$group" new enable=Yes
        }
    } -ArgumentList ($FirewallGroup -join ';')

    Write-LogFunctionExit
}
#endregion Enable-LabVMFirewallGroup

#region Disable-LabVMFirewallGroup
function Disable-LabVMFirewallGroup
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [string[]]$FirewallGroup
    )

    Write-LogFunctionEntry

    $machine = Get-LabVM -ComputerName $ComputerName

    Invoke-LabCommand -ComputerName $machine -ActivityName 'Disable firewall group' -NoDisplay -ScriptBlock `
    {
        param
        (
            [string]$FirewallGroup
        )

        $FirewallGroups = $FirewallGroup.Split(';')

        foreach ($group in $FirewallGroups)
        {
            Write-Verbose -Message "Disable firewall group '$group' on '$(hostname)'"
            netsh.exe advfirewall firewall set rule group="$group" new enable=No
        }
    } -ArgumentList ($FirewallGroup -join ';')

    Write-LogFunctionExit
}
#endregion Disable-LabVMFirewallGroup

#region Test-Port

#endregion Test-Port

#region Get-StringSection
#endregion Get-StringSection

#region Add-StringIncrement

#endregion Add-StringIncrement

#region Get-FullMesh


#endregion Get-FullMesh

#region Get-LabInternetFile
function Get-LabInternetFile
{
    # .ExternalHelp AutomatedLab.Help.xml
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [switch]$Force,

        [switch]$NoDisplay,

        [switch]$PassThru
    )

    function Get-LabInternetFileInternal
    {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Uri,

            [Parameter(Mandatory = $true)]
            [string]$Path,

            [switch]$NoDisplay,

            [switch]$Force
        )

        $internalUri = New-Object System.Uri($Uri)
        $fileName = $internalUri.Segments[$internalUri.Segments.Count - 1]

        if (Test-Path -Path $Path -PathType Container)
        {
            $Path = Join-Path -Path $Path -ChildPath $fileName
        }

        if ((Test-Path -Path $Path) -and -not $Force)
        {
            Write-Verbose -Message "The file '$Path' does already exist, skipping the download"
        }
        else
        {
            if (-not (Get-NetConnectionProfile | Where-Object { $_.IPv4Connectivity -eq 'Internet' -or $_.IPv6Connectivity -eq 'Internet' }))
            {
                #machine does not have internet connectivity
                if (-not $offlineNode)
                {
                    Write-Error "Machine is not connected to the internet and cannot download the file '$Uri'"
                }
                return
            }

            if ((Test-Path -Path $Path) -and $Force)
            {
                Remove-Item -Path $Path -Force
            }

            Write-Verbose "Uri is '$Uri'"
            Write-Verbose "Path os '$Path'"

            try
            {
                try
                {
                    #https://docs.microsoft.com/en-us/dotnet/api/system.net.securityprotocoltype?view=netcore-2.0#System_Net_SecurityProtocolType_SystemDefault
                    if ($PSVersionTable.PSVersion.Major -lt 6 -and [Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12')
                    {
                        Write-Verbose -Message 'Adding support for TLS 1.2'
                        [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
                    }
                }
                catch
                {
                    Write-Warning -Message 'Adding TLS 1.2 to supported security protocols was unsuccessful.'
                }

                $bytesProcessed = 0
                $request = [System.Net.WebRequest]::Create($Uri)
                $request.AllowAutoRedirect = $true

                if ($request)
                {
                    Write-Verbose 'WebRequest created'
                    $response = $request.GetResponse()
                    if ($response)
                    {
                        Write-Verbose 'Responce received'
                        $remoteStream = $response.GetResponseStream()

                        $localStream = [System.IO.File]::Create($Path)

                        $buffer = New-Object System.Byte[] 5MB
                        $bytesRead = 0

                        do
                        {
                            $bytesRead = $remoteStream.Read($buffer, 0, $buffer.Length)
                            $localStream.Write($buffer, 0, $bytesRead)
                            $bytesProcessed += $bytesRead

                            $percentageCompleted = $bytesProcessed / $response.ContentLength
                            if ($percentageCompleted -gt 0)
                            {
                                Write-Progress -Activity "Downloading file '$fileName'" `
                                -Status ("{0:P} completed, {1:N2}MB of {2:N2}MB" -f $percentageCompleted, ($bytesProcessed / 1MB), ($response.ContentLength / 1MB)) `
                                -PercentComplete ($percentageCompleted * 100)
                            }
                            else
                            {
                                Write-Verbose -Message "Could not determine the ContentLength of '$Uri'"
                            }

                        } while ($bytesRead -gt 0)
                    }

                    $response
                }
            }
            catch
            {
                Write-Error -Exception $_.Exception
            }
            finally
            {

                if ($response) { $response.Close() }
                if ($remoteStream) { $remoteStream.Close() }
                if ($localStream) { $localStream.Close() }
            }
        }
    }

    $start = Get-Date

    #TODO: This needs to go into config
    $offlineNode = $true

    if (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $Path)
    {
        $machine = Get-LabVM -IsRunning | Select-Object -First 1
        Write-Verbose "Target path is on AzureLabSources, invoking the copy job on the first available Azure machine."

        $result = Invoke-LabCommand -ComputerName $machine -ScriptBlock (Get-Command -Name Get-LabInternetFileInternal).ScriptBlock -ArgumentList $Uri, $Path -PassThru
    }
    else
    {
        Write-Verbose "Target path is local, invoking the copy job locally."
        $PSBoundParameters.Remove('PassThru') | Out-Null
        $result = Get-LabInternetFileInternal @PSBoundParameters
    }

    $end = Get-Date
    Write-Verbose "Download has taken: $($end - $start)"

    if ($PassThru)
    {
        $uri2 = New-Object System.Uri($Uri)
        New-Object PSObject -Property @{
            Uri = $Uri
            Path = $Path
            FileName = $uri2.Segments[$uri2.Segments.Count-1]
            FullName = Join-Path -Path $Path -ChildPath $uri2.Segments[$uri2.Segments.Count-1]
            Length = $result.ContentLength
        }
    }
}
#endregion Get-LabInternetFile

#region Unblock-LabSources
function Unblock-LabSources
{
    # .ExternalHelp AutomatedLab.Help.xml
    param(
        [string]$Path = $global:labSources
    )

    Write-LogFunctionEntry

    $lab = Get-Lab -ErrorAction SilentlyContinue
    if(-not $lab)
    {
        $lab = Get-LabDefinition -ErrorAction SilentlyContinue
    }

    if($lab.DefaultVirtualizationEngine -eq 'Azure' -and $Path.StartsWith("\\"))
    {
        Write-Verbose 'Skipping the unblocking of lab sources since we are on Azure and lab sources are unblocked during Sync-LabAzureLabSources'
        return
    }

    if (-not (Test-Path -Path $Path))
    {
        Write-Error "The path '$Path' could not be found"
        return
    }

    $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T String, DateTime

    try
    {
        $cache = $type::ImportFromRegistry('Cache', 'Timestamps')
        Write-Verbose 'Imported Cache\Timestamps from regirtry'
    }
    catch
    {
        $cache = New-Object $type
        Write-Verbose 'No entry found in the regirtry at Cache\Timestamps'
    }

    if (-not $cache['LabSourcesLastUnblock'] -or $cache['LabSourcesLastUnblock'] -lt (Get-Date).AddDays(-1))
    {
        Write-Verbose 'Last unblock more than 24 hours ago, unblocking files'
        Get-ChildItem -Path $Path -Recurse | Unblock-File
        $cache['LabSourcesLastUnblock'] = Get-Date
        $cache.ExportToRegistry('Cache', 'Timestamps')
        Write-Verbose 'LabSources folder unblocked and new timestamp written to Cache\Timestamps'
    }
    else
    {
        Write-Verbose 'Last unblock less than 24 hours ago, doing nothing'
    }

    Write-LogFunctionExit
}
#endregion Unblock-LabSources


function Set-LabVMDescription
{
    # .ExternalHelp AutomatedLab.Help.xml
    [CmdletBinding()]
    param (
        [hashtable]$Hashtable,

        [string]$ComputerName
    )

    Write-LogFunctionEntry

    $t = Get-Type -GenericType AutomatedLab.SerializableDictionary -T String,String
    $d = New-Object $t

    foreach ($kvp in $Hashtable.GetEnumerator())
    {
        $d.Add($kvp.Key, $kvp.Value)
    }

    $sb = New-Object System.Text.StringBuilder
    $xmlWriterSettings = New-Object System.Xml.XmlWriterSettings
    $xmlWriterSettings.ConformanceLevel = 'Auto'
    $xmlWriter = [System.Xml.XmlWriter]::Create($sb, $xmlWriterSettings)

    $d.WriteXml($xmlWriter)

    Set-VM -Name $ComputerName -Notes $sb.ToString()

    Write-LogFunctionExit
}

function Get-LabSourcesLocationInternal
{
    param
    (
        [switch]$Local
    )

    $lab = $global:AL_CurrentLab
    
    $defaultEngine = 'HyperV'
    $defaultEngine = if ($lab)
    {
        $lab.DefaultVirtualizationEngine
    }
    
    if ($defaultEngine -eq 'HyperV' -or $Local)
    {
        $hardDrives = (Get-WmiObject -NameSpace Root\CIMv2 -Class Win32_LogicalDisk | Where-Object DriveType -eq 3).DeviceID | Sort-Object -Descending
        
        $folders = foreach ($drive in $hardDrives)
        {
            if (Test-Path -Path "$drive\LabSources")
            {
                "$drive\LabSources"
            }
        }
        
        if ($folders.Count -gt 1)
        {
            Write-Warning "The LabSources folder is available more than once ('$($folders -join "', '")'). The LabSources folder must exist only on one drive and in the root of the drive."
        }
        
        $folders
    }
    elseif ($defaultEngine -eq 'Azure')
    {
        try
        {
            (Get-LabAzureLabSourcesStorage -ErrorAction Stop).Path
        }
        catch
        {
            Get-LabSourcesLocationInternal -Local
        }
    }
    else
    {
        Get-LabSourcesLocationInternal -Local
    }
}

#region Update-LabSysinternalsTools
function Update-LabSysinternalsTools
{
    #Update SysInternals suite if needed
    $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T String, DateTime

    try {
        #https://docs.microsoft.com/en-us/dotnet/api/system.net.securityprotocoltype?view=netcore-2.0#System_Net_SecurityProtocolType_SystemDefault
        if ($PSVersionTable.PSVersion.Major -lt 6 -and [Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12') {
            Write-Verbose -Message 'Adding support for TLS 1.2'
            [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
        }
    }
    catch {
        Write-Warning -Message 'Adding TLS 1.2 to supported security protocols was unsuccessful.'
    }

    try
    {
        Write-Verbose -Message 'Get last check time of SysInternals suite'
        $timestamps = $type::ImportFromRegistry('Cache', 'Timestamps')
        $lastChecked = $timestamps.SysInternalsUpdateLastChecked
        Write-Verbose -Message "Last check was '$lastChecked'."
    }
    catch
    {
        Write-Verbose -Message 'Last check time could not be retrieved. SysInternals suite never updated'
        $lastChecked = Get-Date -Year 1601
        $timestamps = New-Object $type
    }

    if ($lastChecked)
    {
        $lastChecked = $lastChecked.AddDays(7)
    }

    if ((Get-Date) -gt $lastChecked)
    {
        Write-Verbose -Message 'Last check time is more then a week ago. Check web site for update.'

        $sysInternalsUrl = (Get-Module -Name AutomatedLab)[0].PrivateData.SysInternalsUrl
        $sysInternalsDownloadUrl = (Get-Module -Name AutomatedLab)[0].PrivateData.SysInternalsDownloadUrl

        try
        {
            Write-Verbose -Message 'Web page downloaded'
            $webRequest = Invoke-WebRequest -Uri $sysInternalsURL -UseBasicParsing
            $pageDownloaded = $true
        }
        catch
        {
            Write-Verbose -Message 'Web page could not be downloaded'
            Write-ScreenInfo -Message "No connection to '$sysInternalsURL'. Skipping." -Type Error
            $pageDownloaded = $false
        }

        if ($pageDownloaded)
        {
            $updateStart = $webRequest.Content.IndexOf('Updated') + 'Updated:'.Length
            $updateFinish = $webRequest.Content.IndexOf('</p>', $updateStart)
            $updateStringFromWebPage = $webRequest.Content.Substring($updateStart, $updateFinish - $updateStart).Trim()

            Write-Verbose -Message "Update string from web page: '$updateStringFromWebPage'"

            $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T String, String
            try
            {
                $versions = $type::ImportFromRegistry('Cache', 'Versions')
            }
            catch
            {
                $versions = New-Object $type
            }

            Write-Verbose -Message "Update string from registry: '$currentVersion'"

            if ($versions['SysInternals'] -ne $updateStringFromWebPage)
            {
                Write-ScreenInfo -Message 'Performing update of SysInternals suite now' -Type Warning -TaskStart
                Start-Sleep -Seconds 1

                #Download SysInternals suite

                $tempFilePath = [System.IO.Path]::GetTempFileName()
                $tempFilePath = Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::ChangeExtension($tempFilePath, '.zip')) -PassThru
                Write-Verbose -Message "Temp file: '$tempFilePath'"

                try
                {
                    Invoke-WebRequest -Uri $sysInternalsDownloadURL -UseBasicParsing -OutFile $tempFilePath
                    $fileDownloaded = $true
                    Write-Verbose -Message "File '$sysInternalsDownloadURL' downloaded"
                }
                catch
                {
                    Write-ScreenInfo -Message "File '$sysInternalsDownloadURL' could not be downloaded. Skipping." -Type Error -TaskEnd
                    $fileDownloaded = $false
                }

                if ($fileDownloaded)
                {
                    Unblock-File -Path $tempFilePath

                    #Extract files to Tools folder
                    if (-not (Test-Path -Path "$labSources\Tools"))
                    {
                        Write-Verbose -Message "Folder '$labSources\Tools' does not exist. Creating now."
                        New-Item -ItemType Directory -Path "$labSources\Tools" | Out-Null
                    }
                    if (-not (Test-Path -Path "$labSources\Tools\SysInternals"))
                    {
                        Write-Verbose -Message "Folder '$labSources\Tools\SysInternals' does not exist. Creating now."
                        New-Item -ItemType Directory -Path "$labSources\Tools\SysInternals" | Out-Null
                    }
                    else
                    {
                        Write-Verbose -Message "Folder '$labSources\Tools\SysInternals' exist. Removing it now and recreating it."
                        Remove-Item -Path "$labSources\Tools\SysInternals" -Recurse | Out-Null
                        New-Item -ItemType Directory -Path "$labSources\Tools\SysInternals" | Out-Null
                    }

                    Write-Verbose -Message 'Extracting files'
                    Microsoft.PowerShell.Archive\Expand-Archive -Path $tempFilePath -DestinationPath "$labSources\Tools\SysInternals"
                    Remove-Item -Path $tempFilePath

                    #Update registry
                    $versions['SysInternals'] = $updateStringFromWebPage
                    $versions.ExportToRegistry('Cache', 'Versions')

                    $timestamps['SysInternalsUpdateLastChecked'] = Get-Date
                    $timestamps.ExportToRegistry('Cache', 'Timestamps')

                    Write-ScreenInfo -Message "SysInternals Suite has been updated and placed in '$labSources\Tools\SysInternals'" -Type Warning -TaskEnd
                }
            }
        }
    }
}
#endregion Update-LabSysinternalsTools
