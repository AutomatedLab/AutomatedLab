#region Get-LabHyperVAvailableMemory
function Get-LabHyperVAvailableMemory
{
    # .ExternalHelp AutomatedLab.Help.xml
    if ($IsLinux -or $IsMacOS)
    {
        return [int]((Get-Content -Path /proc/meminfo) -replace ':','=' -replace '\skB' | ConvertFrom-StringData).MemTotal
    }

    [int](((Get-CimInstance -Namespace Root\Cimv2 -Class win32_operatingsystem).TotalVisibleMemorySize) / 1kb)
}
#endregion Get-LabHyperVAvailableMemory

#region Reset-AutomatedLab
function Reset-AutomatedLab
{
    Remove-Lab -Confirm:$false
    Remove-Module *
}
#endregion Reset-AutomatedLab

#region Test-FileHashes
function Test-FileHashes
{
    [OutputType([System.Boolean])]
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
            Write-PSFMessage -Level Host -Message "'$File' is missing"
            $Issues = $True
        }
        else
        {
            if ((Get-FileHash -Path $File.path.replace('<MODULEPATH>', $ModulePath)).hash -ne $File.Hash)
            {
                Write-PSFMessage -Level Host -Message "'$File.Path' has wrong hash and is thereby not the file you think it is"
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

    [cmdletbinding()]
    param
    (
        $Filename = 'C:\ALfiles.txt'
    )

    Get-ChildItem $ModulePath -Recurse -Directory -Include 'AutomatedLab', 'AutomatedLabDefinition', 'AutomatedLabUnattended', 'AutomatedLabWorker', 'HostsFile', 'PSFileTransfer', 'PSLog' | ForEach-Object {Get-ChildItem $_.FullName | Select-Object FullName} | Export-Csv -Path $Filename
}
#endregion Save-FileList

#region Test-FileList
function Test-FileList
{
    [OutputType([System.Boolean])]
    [cmdletbinding()]
    param
    (
        $Filename = 'C:\ALfiles.txt'
    )

    $StoredFiles = Import-Csv -Path $Filename
    $Files = Get-ChildItem $ModulePath -Recurse -Directory -Include 'AutomatedLab', 'AutomatedLabDefinition', 'AutomatedLabUnattended', 'AutomatedLabWorker', 'HostsFile', 'PSFileTransfer', 'PSLog' | ForEach-Object {Get-ChildItem $_.FullName | Select-Object FullName}

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

#region Get-LabInternetFile
function Get-LabInternetFile
{

    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$FileName,

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

            [string]$FileName,

            [bool]$NoDisplay,

            [bool]$Force
        )

        if (Test-Path -Path $Path -PathType Container)
        {
            $Path = Join-Path -Path $Path -ChildPath $FileName
        }

        if ((Test-Path -Path $Path -PathType Leaf) -and -not $Force)
        {
            Write-Verbose -Message "The file '$Path' does already exist, skipping the download"
        }
        else
        {
            if (-not ($IsLinux -or $IsMacOS) -and -not (Get-NetConnectionProfile -ErrorAction SilentlyContinue | Where-Object { $_.IPv4Connectivity -eq 'Internet' -or $_.IPv6Connectivity -eq 'Internet' }))
            {
                #machine does not have internet connectivity
                if (-not $offlineNode)
                {
                    Write-Error "Machine is not connected to the internet and cannot download the file '$Uri'"
                }
                return
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
                        Write-Verbose 'Response received'
                        $remoteStream = $response.GetResponseStream()

                        if ([System.IO.Path]::GetPathRoot($Path) -ne $Path)
                        {
                            $parent = Split-Path -Path $Path
                        }
                        if (-not (Test-Path -Path $parent -PathType Container) -and -not ([System.IO.Path]::GetPathRoot($parent) -eq $parent))
                        {
                            New-Item -Path $parent -ItemType Directory -Force | Out-Null
                        }
                        if ((Test-Path -Path $Path -PathType Container) -and -not $FileName)
                        {
                            $FileName = $response.ResponseUri.Segments[-1]
                            $Path = Join-Path -Path $Path -ChildPath $FileName
                        }
                        if ([System.IO.Path]::GetPathRoot($Path) -eq $Path)
                        {
                            Write-Error "The path '$Path' is the drive root and the file name could not be retrived using the given url. Please provide a file name using the 'FileName' parameter."
                            return
                        }
                        if (-not $FileName)
                        {
                            $FileName = Split-Path -Path $Path -Leaf
                        }
                        if ((Test-Path -Path $Path -PathType Leaf) -and -not $Force)
                        {
                            Write-Verbose -Message "The file '$Path' does already exist, skipping the download"
                        }
                        else
                        {
                            $localStream = [System.IO.File]::Create($Path)

                            $buffer = New-Object System.Byte[] 10MB
                            $bytesRead = 0
                            [int]$percentageCompletedPrev = 0

                            do
                            {
                                $bytesRead = $remoteStream.Read($buffer, 0, $buffer.Length)
                                $localStream.Write($buffer, 0, $bytesRead)
                                $bytesProcessed += $bytesRead

                                [int]$percentageCompleted = $bytesProcessed / $response.ContentLength * 100
                                if ($percentageCompleted -gt 0)
                                {
                                    if ($percentageCompletedPrev -ne $percentageCompleted)
                                    {
                                        $percentageCompletedPrev = $percentageCompleted
                                        Write-Progress -Activity "Downloading file '$FileName'" `
                                        -Status ("{0:P} completed, {1:N2}MB of {2:N2}MB" -f ($percentageCompleted / 100), ($bytesProcessed / 1MB), ($response.ContentLength / 1MB)) `
                                        -PercentComplete ($percentageCompleted)
                                    }
                                }
                                else
                                {
                                    Write-Verbose -Message "Could not determine the ContentLength of '$Uri'"
                                }
                            } while ($bytesRead -gt 0)
                        }
                    }

                    $response | Add-Member -Name FileName -MemberType NoteProperty -Value $FileName -PassThru
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

    if (-not $FileName)
    {
        $internalUri = New-Object System.Uri($Uri)
        $tempFileName = $internalUri.Segments[$internalUri.Segments.Count - 1]
        if (Test-FileName -Path $tempFileName)
        {
            $FileName = $tempFileName
            $PSBoundParameters.FileName = $FileName
        }
    }

    $lab = Get-Lab -ErrorAction SilentlyContinue
    if (-not $lab)
    {
        $lab = Get-LabDefinition -ErrorAction SilentlyContinue
        $doNotGetVm = $true
    }

    if ($lab.DefaultVirtualizationEngine -eq 'Azure')
    {
        if (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $Path)
        {
            # We need to test first, even if it takes a second longer.
            if (-not $doNotGetVm)
            {
                $machine =  Invoke-LabCommand -PassThru -NoDisplay -ComputerName $(Get-LabVM -IsRunning) -ScriptBlock {
                    if (Get-NetConnectionProfile -IPv4Connectivity Internet -ErrorAction SilentlyContinue)
                    {
                        hostname
                    }
                } -ErrorAction SilentlyContinue | Select-Object -First 1 
                Write-PSFMessage "Target path is on AzureLabSources, invoking the copy job on the first available Azure machine."

                $argumentList = $Uri, $Path, $FileName

                $argumentList += if ($NoDisplay) { $true } else { $false }
                $argumentList += if ($Force) { $true } else { $false }
            }

            if ($machine)
            {
                $result = Invoke-LabCommand -ActivityName "Downloading file from '$Uri'" -ComputerName $machine -ScriptBlock (Get-Command -Name Get-LabInternetFileInternal).ScriptBlock -ArgumentList $argumentList -PassThru
            }
            elseif (Get-LabAzureSubscription -ErrorAction SilentlyContinue)
            {
                $blob = $Path.Replace("$(Get-LabSourcesLocation)\",'')
                $PSBoundParameters.Remove('PassThru') | Out-Null
                $param = Sync-Parameter -Command (Get-Command Get-LabInternetFileInternal) -Parameters $PSBoundParameters
                $param['Path'] = $Path.Replace((Get-LabSourcesLocation), (Get-LabSourcesLocation -Local))

                $result = Get-LabInternetFileInternal @param
                $fullName = Join-Path -Path $param.Path.Replace($FileName,'') -ChildPath (?? { $FileName } { $FileName } { $result.FileName })
                $storageAccount = Get-AzStorageAccount -ResourceGroupName automatedlabsources | Where-Object StorageAccountName -like automatedlabsources?????
                
                $container = Split-Path -Path $blob
                $blobName = Split-Path -Path $blob -Leaf
                New-AzStorageDirectory -Share (Get-AzStorageShare -Name labsources -Context $storageAccount.Context).CloudFileShare -Path $container -ErrorVariable err -ErrorAction SilentlyContinue | Out-Null
                Write-PSFMessage "Created directory $($container) in labsources"
                if ($err)
                {
                    $err = $null

                    # Use an error variable and check the HttpStatusCode since there is no cmdlet to get or test a StorageDirectory
                    New-AzStorageDirectory -Share (Get-AzStorageShare -Name labsources -Context $storageAccount.Context).CloudFileShare -Path $container -ErrorVariable err -ErrorAction SilentlyContinue | Out-Null
                    Write-PSFMessage "Created directory '$container' in labsources"
                    if ($err)
                    {
                        if ($err[0].Exception.RequestInformation.HttpStatusCode -ne 409)
                        {
                            throw "An error ocurred during file upload: $($err[0].Exception.Message)"
                        }
                    }
                }

                $azureFile = Get-AzStorageFile -Share (Get-AzStorageShare -Name labsources -Context $storageAccount.Context).CloudFileShare -Path $blobName -ErrorAction SilentlyContinue
                if ($azureFile)
                {
                    $azureHash = $azureFile.CloudFile.Properties.ContentMD5
                    $fileHash = (Get-FileHash -Path $fullName -Algorithm MD5).Hash
                    Write-PSFMessage "$blobName already exists in Azure. Source hash is $fileHash and Azure hash is $azureHash"
                }

                if (-not $azureFile -or ($azureFile -and $fileHash -ne $azureHash))
                {
                    $null = Set-AzStorageFileContent -Share (Get-AzStorageShare -Name labsources -Context $storageAccount.Context).CloudFileShare -Source $fullName -Path $blobName -ErrorAction SilentlyContinue -Force
                    Write-PSFMessage "Azure file $blobName successfully uploaded. Generating file hash..."
                }
            }
            else
            {
                Write-ScreenInfo -Type Erro -Message "Unable to upload file to Azure lab sources - No VM is available and no Azure subscription was added to the lab`r`n
                Please at least execute New-LabDefinition and Add-LabAzureSubscription before using Get-LabInternetFile"
                return
            }
        }
        else
        {
            Write-PSFMessage "Target path is local, invoking the copy job locally."
            $PSBoundParameters.Remove('PassThru') | Out-Null
            $result = Get-LabInternetFileInternal @PSBoundParameters
        }
    }
    else
    {
        Write-PSFMessage "Target path is local, invoking the copy job locally."
        $PSBoundParameters.Remove('PassThru') | Out-Null
        try
        {
            $result = Get-LabInternetFileInternal @PSBoundParameters

            $end = Get-Date
            Write-PSFMessage "Download has taken: $($end - $start)"
        }
        catch
        {
            Write-Error -ErrorRecord $_
        }
    }

    if ($PassThru)
    {
        New-Object PSObject -Property @{
            Uri = $Uri
            Path = $Path
            FileName = ?? { $FileName } { $FileName } { $result.FileName }
            FullName = Join-Path -Path $Path -ChildPath (?? { $FileName } { $FileName } { $result.FileName })
            Length = $result.ContentLength
        }
    }
}
#endregion Get-LabInternetFile

#region Unblock-LabSources
function Unblock-LabSources
{

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
        Write-PSFMessage 'Skipping the unblocking of lab sources since we are on Azure and lab sources are unblocked during Sync-LabAzureLabSources'
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
        if ($IsLinux -or $IsMacOs)
        {
            $cache = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/Timestamps.xml'))
        }
        else
        {
            $cache = $type::ImportFromRegistry('Cache', 'Timestamps')
        }

        Write-PSFMessage 'Imported Cache\Timestamps from registry/file store'
    }
    catch
    {
        $cache = New-Object $type
        Write-PSFMessage 'No entry found in the registry at Cache\Timestamps'
    }

    if (-not $cache['LabSourcesLastUnblock'] -or $cache['LabSourcesLastUnblock'] -lt (Get-Date).AddDays(-1))
    {
        Write-PSFMessage 'Last unblock more than 24 hours ago, unblocking files'
        if (-not ($IsLinux -or $IsMacOs)) { Get-ChildItem -Path $Path -Recurse | Unblock-File }
        $cache['LabSourcesLastUnblock'] = Get-Date
        if ($IsLinux -or $IsMacOs)
        {
            $cache.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/Timestamps.xml'))
        }
        else
        {
            $cache.ExportToRegistry('Cache', 'Timestamps')
        }

        Write-PSFMessage 'LabSources folder unblocked and new timestamp written to Cache\Timestamps'
    }
    else
    {
        Write-PSFMessage 'Last unblock less than 24 hours ago, doing nothing'
    }

    Write-LogFunctionExit
}
#endregion Unblock-LabSources

#region Set-LabVMDescription
function Set-LabVMDescription
{

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
#endregion Set-LabVMDescription

#region Get-LabSourcesLocationInternal
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

    if ($defaultEngine -eq 'kvm' -or ($IsLinux -and $Local.IsPresent))
    {
        if (-not (Get-PSFConfigValue -FullName AutomatedLab.LabSourcesLocation))
        {
            Set-PSFConfig -Module AutomatedLab -Name LabSourcesLocation -Description 'Location of lab sources folder' -Value $home/automatedlabsources -PassThru | Register-PSFConfig
        }

        Get-PSFConfigValue -FullName AutomatedLab.LabSourcesLocation
    }
    elseif (($defaultEngine -eq 'HyperV' -or $Local) -and (Get-PSFConfigValue AutomatedLab.LabSourcesLocation))
    {
        Get-PSFConfigValue -FullName AutomatedLab.LabSourcesLocation
    }
    elseif ($defaultEngine -eq 'HyperV' -or $Local)
    {
        $hardDrives = (Get-CimInstance -NameSpace Root\CIMv2 -Class Win32_LogicalDisk | Where-Object DriveType -In 2, 3).DeviceID | Sort-Object -Descending

        $folders = foreach ($drive in $hardDrives)
        {
            if (Test-Path -Path "$drive\LabSources")
            {
                "$drive\LabSources"
            }
        }

        if ($folders.Count -gt 1)
        {
            Write-PSFMessage -Level Warning "The LabSources folder is available more than once ('$($folders -join "', '")'). The LabSources folder must exist only on one drive and in the root of the drive."
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
#endregion Get-LabSourcesLocationInternal

#region Update-LabSysinternalsTools
function Update-LabSysinternalsTools
{
    if ($IsLinux -or $IsMacOs) { return }
    #Update SysInternals suite if needed
    $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T String, DateTime

    try {
        #https://docs.microsoft.com/en-us/dotnet/api/system.net.securityprotocoltype?view=netcore-2.0#System_Net_SecurityProtocolType_SystemDefault
        if ($PSVersionTable.PSVersion.Major -lt 6 -and [Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12') {
            Write-PSFMessage -Message 'Adding support for TLS 1.2'
            [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
        }
    }
    catch {
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

                $tempFilePath = [System.IO.Path]::GetTempFileName()
                $tempFilePath = Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::ChangeExtension($tempFilePath, '.zip')) -PassThru
                Write-PSFMessage -Message "Temp file: '$tempFilePath'"

                try
                {
                    Invoke-WebRequest -Uri $sysInternalsDownloadURL -UseBasicParsing -OutFile $tempFilePath
                    $fileDownloaded = $true
                    Write-PSFMessage -Message "File '$sysInternalsDownloadURL' downloaded"
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
                    Microsoft.PowerShell.Archive\Expand-Archive -Path $tempFilePath -DestinationPath "$labSources\Tools\SysInternals"
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
#endregion Update-LabSysinternalsTools

#region Register-LabArgumentCompleters
function Register-LabArgumentCompleters
{
    $commands = Get-Command -Module AutomatedLab*, PSFileTransfer | Where-Object { $_.Parameters -and $_.Parameters.ContainsKey('ComputerName') }

    Register-PSFTeppArgumentCompleter -Command $commands -Parameter ComputerName -Name 'AutomatedLab-ComputerName'
}
#endregion Register-LabArgumentCompleters

#region Test-FileName
function Test-FileName
{
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    $fi = $null
    try {
        $fi = New-Object System.IO.FileInfo($Path)
    }
    catch [ArgumentException] { }
    catch [System.IO.PathTooLongException] { }
    catch [NotSupportedException] { }
    if ([object]::ReferenceEquals($fi, $null) -or $fi.Name -eq '') {
        return $false
    } else {
        return $true
    }
}
#endregion Test-FileName
