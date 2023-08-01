function Send-FtpFolder
{
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [Parameter(Mandatory)]
        [string]$HostUrl,

        [Parameter(Mandatory)]
        [System.Net.NetworkCredential]$Credential,

        [switch]$Recure
    )

    Add-Type -Path (Join-Path -Path (Get-Module AutomatedLabCore).ModuleBase -ChildPath 'Tools\FluentFTP.dll')
    $fileCount = 0

    if (-not (Test-Path -Path $Path -PathType Container))
    {
        Write-Error "The folder '$Path' does not exist or is not a directory."
        return
    }

    $client = New-Object FluentFTP.FtpClient("ftp://$HostUrl", $Credential)
    try
    {
        $client.DataConnectionType = [FluentFTP.FtpDataConnectionType]::PASV
        $client.Connect()
    }
    catch
    {
        Write-Error -Message "Could not connect to FTP server: $($_.Exception.Message)" -Exception $_.Exception
        return
    }

    if ($DestinationPath.Contains('\'))
    {
        Write-Error "The destination path cannot contain backslashes. Please use forward slashes to separate folder names."
        return
    }

    if (-not $DestinationPath.EndsWith('/'))
    {
        $DestinationPath += '/'
    }

    $files = Get-ChildItem -Path $Path -File -Recurse:$Recure
    Write-PSFMessage "Sending folder '$Path' with $($files.Count) files"

    foreach ($file in $files)
    {
        $fileCount++
        Write-PSFMessage "Sending file $($file.FullName) ($fileCount)"
        Write-Progress -Activity "Uploading file '$($file.FullName)'" -Status x -PercentComplete ($fileCount / $files.Count * 100)
        $relativeFullName = $file.FullName.Replace($path, '').Replace('\', '/')
        if ($relativeFullName.StartsWith('/')) { $relativeFullName = $relativeFullName.Substring(1) }
        $newDestinationPath = $DestinationPath + $relativeFullName

        try
        {
            $result = $client.UploadFile($file.FullName, $newDestinationPath, 'Overwrite', $true, 'Retry')
        }
        catch
        {
            Write-Error -Exception $_.Exception
            $client.Disconnect()
            return
        }
        if (-not $result)
        {
            Write-Error "There was an error uploading file '$($file.FullName)'. Canelling the upload process."
            $client.Disconnect()
            return
        }
    }

    Write-PSFMessage "Finsihed sending folder '$Path'"

    $client.Disconnect()
}
