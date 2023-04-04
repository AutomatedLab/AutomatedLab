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
            Write-Verbose "Path is '$Path'"

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
                $machine = Invoke-LabCommand -PassThru -NoDisplay -ComputerName $(Get-LabVM -IsRunning) -ScriptBlock {
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
                $result = Invoke-LabCommand -ActivityName "Downloading file from '$Uri'" -NoDisplay:$NoDisplay.IsPresent -ComputerName $machine -ScriptBlock (Get-Command -Name Get-LabInternetFileInternal).ScriptBlock -ArgumentList $argumentList -PassThru
            }
            elseif (Get-LabAzureSubscription -ErrorAction SilentlyContinue)
            {
                $PSBoundParameters.Remove('PassThru') | Out-Null
                $param = Sync-Parameter -Command (Get-Command Get-LabInternetFileInternal) -Parameters $PSBoundParameters
                $param['Path'] = $Path.Replace((Get-LabSourcesLocation), (Get-LabSourcesLocation -Local))
                $result = Get-LabInternetFileInternal @param

                $fullName = Join-Path -Path $param.Path.Replace($FileName, '') -ChildPath (?? { $FileName } { $FileName } { $result.FileName })
                $pathFilter = $fullName.Replace("$(Get-LabSourcesLocation -Local)\", '')
                Sync-LabAzureLabSources -Filter $pathFilter -NoDisplay
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
            Uri      = $Uri
            Path     = $Path
            FileName = ?? { $FileName } { $FileName } { $result.FileName }
            FullName = Join-Path -Path $Path -ChildPath (?? { $FileName } { $FileName } { $result.FileName })
            Length   = $result.ContentLength
        }
    }
}
