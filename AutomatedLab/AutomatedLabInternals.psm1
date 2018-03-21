
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
        Remove-Item -Path c:\unattend.xml
        Remove-Item -Path c:\WSManRegKey.reg
        Remove-Item -Path c:\DeployDebug -Recurse
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
        
        [switch]$PassThru
    )
    
    function Get-LabInternetFileInternal
    {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Uri,

            [Parameter(Mandatory = $true)]
            [string]$Path,

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
            Write-ScreenInfo "The file '$Path' does already exist, skipping the download"
        }
        else
        {
            if ((Test-Path -Path $Path) -and $Force)
            {
                Remove-Item -Path $Path -Force
            }
    
            Write-Verbose "Uri is '$Uri'"
            Write-Verbose "Path os '$Path'"

            try
            {
                $bytesProcessed = 0
                $request = [System.Net.WebRequest]::Create($Uri)
                $request.AllowAutoRedirect = $true
                
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
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
                                Write-ScreenInfo -Message "Could not determine the ContentLength of '$Uri'" -Type Verbose
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
    $lab = Get-Lab -ErrorAction SilentlyContinue
    $labDefinition = Get-LabDefinition -ErrorAction SilentlyContinue

    $defaultEngine = 'HyperV'
    if ($lab)
    {
        $defaultEngine = $lab.DefaultVirtualizationEngine
    }
    elseif ($labDefinition)
    {
        $defaultEngine = $labDefinition.DefaultVirtualizationEngine
    }

    if ($defaultEngine -eq 'HyperV' -or $Local)
    {
        $hardDrives = (Get-WmiObject -NameSpace Root\CIMv2 -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}).DeviceID | Sort-Object -Descending

        foreach ($drive in $hardDrives)
        {
            if (Test-Path -Path "$drive\LabSources")
            {
                "$drive\LabSources"
            }
        }
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