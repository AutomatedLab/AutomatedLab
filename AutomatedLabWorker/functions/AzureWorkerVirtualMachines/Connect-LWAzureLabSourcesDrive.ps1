function Connect-LWAzureLabSourcesDrive
{
    param(
        [Parameter(Mandatory, Position = 0)]
        [System.Management.Automation.Runspaces.PSSession]$Session,

        [switch]$SuppressErrors
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount
    $labSourcesStorageAccount = Get-LabAzureLabSourcesStorage -ErrorAction SilentlyContinue

    if ($Session.Runspace.ConnectionInfo.AuthenticationMechanism -notin 'CredSsp', 'Negotiate' -or -not $labSourcesStorageAccount)
    {
        return
    }

    $result = Invoke-Command -Session $Session -ScriptBlock {
        #Add *.windows.net to Local Intranet Zone
        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\windows.net'
        if (-not (Test-Path -Path $path)) {
            New-Item -Path $path -Force

            New-ItemProperty $path -Name http -Value 1 -Type DWORD
            New-ItemProperty $path -Name file -Value 1 -Type DWORD
        }

        $hostName = ([uri]$args[0]).Host
	    $dnsRecord = Resolve-DnsName -Name $hostname | Where-Object { $_ -is [Microsoft.DnsClient.Commands.DnsRecord_A] }
        $ipAddress = $dnsRecord.IPAddress
        $rangeName = $ipAddress.Replace('.', '')

        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\$rangeName"
        if (-not (Test-Path -Path $path)) {
            New-Item -Path $path -Force

            New-ItemProperty $path -Name :Range -Value $ipAddress -Type String
            New-ItemProperty $path -Name http -Value 1 -Type DWORD
            New-ItemProperty $path -Name file -Value 1 -Type DWORD
        }

        $pattern = '^(OK|Unavailable) +(?<DriveLetter>\w): +\\\\automatedlab'

        #remove all drive connected to an Azure LabSources share that are no longer available
        $drives = net.exe use
        $netRemoveResult = @()
        foreach ($line in $drives)
        {
            if ($line -match $pattern)
            {
                $netRemoveResult += net.exe use "$($Matches.DriveLetter):" /d
            }
        }

        $cmd = 'net.exe use * {0} /u:{1} {2}' -f $args[0], $args[1], $args[2]
        $cmd = [scriptblock]::Create($cmd)
        $netConnectResult = &$cmd 2>&1

        if (-not $LASTEXITCODE)
        {
            $ALLabSourcesMapped = $true
            $alDriveLetter = (Get-PSDrive | Where-Object DisplayRoot -like \\automatedlabsources*).Name
            Get-ChildItem -Path "$($alDriveLetter):" | Out-Null #required, otherwise sometimes accessing the UNC path did not work
        }

        New-Object PSObject -Property @{
            ReturnCode         = $LASTEXITCODE
            ALLabSourcesMapped = [bool](-not $LASTEXITCODE)
            NetConnectResult   = $netConnectResult
            NetRemoveResult    = $netRemoveResult
        }

    } -ArgumentList $labSourcesStorageAccount.Path, $labSourcesStorageAccount.StorageAccountName, $labSourcesStorageAccount.StorageAccountKey

    $Session | Add-Member -Name ALLabSourcesMappingResult -Value $result -MemberType NoteProperty -Force
    $Session | Add-Member -Name ALLabSourcesMapped -Value $result.ALLabSourcesMapped -MemberType NoteProperty -Force

    if ($result.ReturnCode -ne 0 -and -not $SuppressErrors)
    {
        $netResult = $result | Where-Object { $_.ReturnCode -gt 0 }
        Write-LogFunctionExitWithError -Message "Connecting session '$($s.Name)' to LabSources folder failed" -Details $netResult.NetConnectResult
    }

    Write-LogFunctionExit
}
