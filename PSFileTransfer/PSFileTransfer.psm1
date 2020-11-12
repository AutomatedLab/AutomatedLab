$chunkSize = 1MB

#region Internals
#region Get-Type (helper function for creating generic types)
function Get-Type
{
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string] $GenericType,

        [Parameter(Position = 1, Mandatory = $true)]
        [string[]] $T
    )

    $T = $T -as [type[]]

    try
    {
        $generic = [type]($GenericType + '`' + $T.Count)
        $generic.MakeGenericType($T)
    }
    catch
    {
        throw New-Object -TypeName System.Exception -ArgumentList ('Cannot create generic type', $_.Exception)
    }
}
#endregion
#region Invoke-Ternary
function Invoke-Ternary ([scriptblock]$decider, [scriptblock]$ifTrue, [scriptblock]$ifFalse)
{
    if (&$decider)
    {
        &$ifTrue
    }
    else
    {
        &$ifFalse
    }
}
Set-Alias -Name ?? -Value Invoke-Ternary -Option AllScope -Description "Ternary Operator like '?' in C#"
#endregion
#endregion

#region File Transfer Functions
#region Send-File
function Send-File
{
    <#
            .SYNOPSIS

            Sends a file to a remote session.

            .EXAMPLE

            PS >$session = New-PsSession leeholmes1c23
            PS >Send-File c:\temp\test.exe c:\temp\test.exe $session
    #>

    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceFilePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationFolderPath,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session,

        [switch]$Force
    )

    $firstChunk = $true

    Write-Verbose -Message "PSFileTransfer: Sending file $SourceFilePath to $DestinationFolderPath on $($Session.ComputerName) ($([Math]::Round($chunkSize / 1MB, 2)) MB chunks)"

    $sourcePath = (Resolve-Path $SourceFilePath -ErrorAction SilentlyContinue).Path
    $sourcePath = Convert-Path $sourcePath
    if (-not $sourcePath)
    {
        Write-Error -Message 'Source file could not be found.'
        return
    }

    if (-not (Test-Path -Path $SourceFilePath -PathType Leaf))
    {
        Write-Error -Message 'Source path points to a directory and not a file.'
        return
    }

    $sourceFileStream = [System.IO.File]::OpenRead($sourcePath)

    for ($position = 0; $position -lt $sourceFileStream.Length; $position += $chunkSize)
    {
        $remaining = $sourceFileStream.Length - $position
        $remaining = [Math]::Min($remaining, $chunkSize)

        $chunk = New-Object -TypeName byte[] -ArgumentList $remaining
        [void]$sourceFileStream.Read($chunk, 0, $remaining)

        $destinationFullName = Join-Path -Path $DestinationFolderPath -ChildPath (Split-Path -Path $SourceFilePath -Leaf)

        try
        {
            Invoke-Command -Session $Session -ScriptBlock (Get-Command Write-File).ScriptBlock `
                -ArgumentList $destinationFullName, $chunk, $firstChunk, $Force -ErrorAction Stop
        }
        catch
        {
            Write-Error -Message "Could not write destination file. The error was '$($_.Exception.Message)'. Please use the Force switch if the destination folder does not exist" -Exception $_.Exception
            return
        }

        $firstChunk = $false
    }

    $sourceFileStream.Close()

    Write-Verbose -Message "PSFileTransfer: Finished sending file $SourceFilePath"
}
#endregion Send-File

#region Receive-File
function Receive-File
{
    <#
            .SYNOPSIS

            Receives a file from a remote session.

            .EXAMPLE

            PS >$session = New-PsSession leeholmes1c23
            PS >Receive-File c:\temp\test.exe c:\temp\test.exe $session
    #>

    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceFilePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationFilePath,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession] $Session
    )

    $firstChunk = $true

    Write-Verbose -Message "PSFileTransfer: Receiving file $SourceFilePath to $DestinationFilePath from $($Session.ComputerName) ($([Math]::Round($chunkSize / 1MB, 2)) MB chunks)"

    $sourceLength = Invoke-Command -Session $Session -ScriptBlock (Get-Command Get-FileLength).ScriptBlock `
        -ArgumentList $SourceFilePath -ErrorAction Stop

    $chunkSize = [Math]::Min($sourceLength, $chunkSize)

    for ($position = 0; $position -lt $sourceLength; $position += $chunkSize)
    {
        $remaining = $sourceLength - $position
        $remaining = [Math]::Min($remaining, $chunkSize)

        try
        {
            $chunk = Invoke-Command -Session $Session -ScriptBlock (Get-Command Read-File).ScriptBlock `
                -ArgumentList $SourceFilePath, $position, $remaining -ErrorAction Stop
        }
        catch
        {
            Write-Error -Message 'Could not read destination file' -Exception $_.Exception
            return
        }

        Write-File -DestinationFullName $DestinationFilePath -Bytes $chunk.Bytes -Erase $firstChunk

        $firstChunk = $false
    }

    Write-Verbose -Message "PSFileTransfer: Finished receiving file $SourceFilePath"
}
#endregion Receive-File

#region Receive-Directory
function Receive-Directory
{
    param (
        ## The target path on the remote computer
        [Parameter(Mandatory = $true)]
        $SourceFolderPath,

        ## The path on the local computer
        [Parameter(Mandatory = $true)]
        $DestinationFolderPath,

        ## The session that represents the remote computer
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession] $Session
    )
    Write-Verbose -Message "Receive-Directory $($env:COMPUTERNAME): remote source $SourceFolderPath, local destination $DestinationFolderPath, session $($Session.ComputerName)"

    $remoteDir = Invoke-Command -Session $Session -ScriptBlock {
        param ($Source)

        Get-Item $Source -Force
    } -ArgumentList $SourceFolderPath -ErrorAction Stop

    if (-not $remoteDir.PSIsContainer)
    {
        Receive-File -SourceFilePath $SourceFolderPath -DestinationFilePath $DestinationFolderPath -Session $Session
    }

    if (-not (Test-Path -Path $DestinationFolderPath))
    {
        New-Item -Path $DestinationFolderPath -ItemType Container -ErrorAction Stop | Out-Null
    }
    elseif (-not (Test-Path -Path $DestinationFolderPath -PathType Container))
    {
        throw "$DestinationFolderPath exists and is not a directory"
    }

    $remoteItems = Invoke-Command -Session $Session -ScriptBlock {
        param ($remoteDir)

        Get-ChildItem $remoteDir -Force
    } -ArgumentList $remoteDir -ErrorAction Stop
    $position = 0

    foreach ($remoteItem in $remoteItems)
    {
        $itemSource = Join-Path -Path $SourceFolderPath -ChildPath $remoteItem.Name

        $itemDestination = Join-Path -Path $DestinationFolderPath -ChildPath $remoteItem.Name
        if ($remoteItem.PSIsContainer)
        {
            $null = Receive-Directory -SourceFolderPath $itemSource -DestinationFolderPath $itemDestination -Session $Session
        }
        else
        {
            $null = Receive-File -SourceFilePath $itemSource -DestinationFilePath $itemDestination -Session $Session
        }
        $position++
    }
}
#endregion Receive-Directory

#region Send-Directory
function Send-Directory
{
    param (
        ## The path on the local computer
        [Parameter(Mandatory = $true)]
        $SourceFolderPath,

        ## The target path on the remote computer
        [Parameter(Mandatory = $true)]
        $DestinationFolderPath,

        ## The session that represents the remote computer
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session
    )

    $isCalledRecursivly = (Get-PSCallStack | Where-Object -Property Command -EQ -Value $MyInvocation.InvocationName | Measure-Object | Select-Object -ExpandProperty Count) -gt 1
    if ($DestinationFolderPath -ne '/' -and -not $DestinationFolderPath.EndsWith('\')) { $DestinationFolderPath = $DestinationFolderPath + '\' }

    if (-not $isCalledRecursivly)
    {
        $initialDestinationFolderPath = $DestinationFolderPath
        $initialSource = $SourceFolderPath
        $initialSourceParent = Split-Path -Path $initialSource -Parent
    }

    Write-Verbose -Message "Send-Directory $($env:COMPUTERNAME): local source $SourceFolderPath, remote destination $DestinationFolderPath, session $($Session.ComputerName)"

    $localDir = Get-Item $SourceFolderPath -ErrorAction Stop -Force
    if (-not $localDir.PSIsContainer)
    {
        Send-File -SourceFilePath $SourceFolderPath -DestinationFolderPath $DestinationFolderPath -Session $Session -Force
        return
    }

    Invoke-Command -Session $Session -ScriptBlock {
        param ($DestinationPath)

        if (-not (Test-Path $DestinationPath))
        {
            $null = New-Item -ItemType Directory -Path $DestinationPath -ErrorAction Stop
        }
        elseif (-not (Test-Path $DestinationPath -PathType Container))
        {
            throw "$DestinationPath exists and is not a directory"
        }
    } -ArgumentList $DestinationFolderPath -ErrorAction Stop

    $localItems = Get-ChildItem -Path $localDir -ErrorAction Stop -Force
    $position = 0

    foreach ($localItem in $localItems)
    {
        $itemSource = Join-Path -Path $SourceFolderPath -ChildPath $localItem.Name
        $newDestinationFolder = $itemSource.Replace($initialSourceParent, $initialDestinationFolderPath).Replace('\\', '\')

        if ($localItem.PSIsContainer)
        {
            $null = Send-Directory -SourceFolderPath $itemSource -DestinationFolderPath $newDestinationFolder -Session $Session
        }
        else
        {
            $newDestinationFolder = Split-Path -Path $newDestinationFolder -Parent
            $null = Send-File -SourceFilePath $itemSource -DestinationFolderPath $newDestinationFolder -Session $Session -Force
        }
        $position++
    }
}
#endregion Send-Directory
#endregion File Transfer Functions

#region Write-File
function Write-File
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$DestinationFullName,

        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes,

        [bool]$Erase,

        [bool]$Force
    )

    Write-Debug -Message "Send-File $($env:COMPUTERNAME): writing $DestinationFullName length $($Bytes.Length)"

    #Convert the destination path to a full filesytem path (to support relative paths)
    try
    {
        $DestinationFullName = $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationFullName)
    }
    catch
    {
        throw New-Object -TypeName System.IO.FileNotFoundException -ArgumentList ('Could not set destination path', $_)
    }

    if ((Test-Path -Path $DestinationFullName -PathType Container))
    {
        Write-Error "Please define the target file's full name. '$DestinationFullName' points to a folder."
        return
    }

    if ($Erase)
    {
        Remove-Item $DestinationFullName -Force -ErrorAction SilentlyContinue
    }

    if ($Force)
    {
        $parentPath = Split-Path -Path $DestinationFullName -Parent
        if (-not (Test-Path -Path $parentPath))
        {
            Write-Verbose -Message "Force is set and destination folder '$parentPath' does not exist, creating it."
            New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
        }
    }

    $destFileStream = [System.IO.File]::OpenWrite($DestinationFullName)
    $destBinaryWriter = New-Object -TypeName System.IO.BinaryWriter -ArgumentList ($destFileStream)

    [void]$destBinaryWriter.Seek(0, 'End')

    $destBinaryWriter.Write($Bytes)

    $destBinaryWriter.Close()
    $destFileStream.Close()

    $Bytes = $null
    [GC]::Collect()
}
#endregion Write-File

#region Read-File
function Read-File
{
    [OutputType([Byte[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceFile,

        [Parameter(Mandatory = $true)]
        [int]$Offset,

        [int]$Length
    )

    #Convert the destination path to a full filesytem path (to support relative paths)
    try
    {
        $sourcePath = $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SourceFile)
    }
    catch
    {
        throw New-Object -TypeName System.IO.FileNotFoundException
    }

    if (-not (Test-Path -Path $SourceFile))
    {
        throw 'Source file could not be found'
    }

    $sourceFileStream = [System.IO.File]::OpenRead($sourcePath)

    $chunk = New-Object -TypeName byte[] -ArgumentList $Length
    [void]$sourceFileStream.Seek($Offset, 'Begin')
    [void]$sourceFileStream.Read($chunk, 0, $Length)

    $sourceFileStream.Close()

    return @{ Bytes = $chunk }
}
#endregion Read-File

#region Get-FileLength
function Get-FileLength
{
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try
    {
        $FilePath = $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath)
    }
    catch
    {
        throw $_
    }

    (Get-Item -Path $FilePath -Force).Length
}
#endregion Get-FileLength

#region Copy-LabFileItem
function Copy-LabFileItem
{
    param (
        [Parameter(Mandatory)]
        [string[]]$Path,

        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [string]$DestinationFolderPath,

        [switch]$Recurse,

        [bool]$FallbackToPSSession = $true,

        [bool]$UseAzureLabSourcesOnAzureVm = $true,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    $machines = Get-LabVM -ComputerName $ComputerName
    if (-not $machines)
    {
        Write-LogFunctionExitWithError -Message 'The specified machines could not be found'
        return
    }
    if ($machines.Count -ne $ComputerName.Count)
    {
        $machinesNotFound = Compare-Object -ReferenceObject $ComputerName -DifferenceObject ($machines.Name)
        Write-ScreenInfo "The specified machine(s) $($machinesNotFound.InputObject -join ', ') could not be found" -Type Warning
    }

    $connectedMachines = @{ }

    foreach ($machine in $machines)
    {
        $cred = $machine.GetCredential((Get-Lab))

        if ($machine.HostType -eq 'HyperV' -or
            (-not $UseAzureLabSourcesOnAzureVm -and $machine.HostType -eq 'Azure') -or
            ($path -notlike "$labSources*" -and $machine.HostType -eq 'Azure')
        )
        {
            try
            {
                if ($DestinationFolderPath -match ':')
                {
                    $letter = ($DestinationFolderPath -split ':')[0]
                    $drive = New-PSDrive -Name "$($letter)_on_$machine" -PSProvider FileSystem -Root "\\$machine\$($letter)`$" -Credential $cred -ErrorAction Stop
                }
                else
                {
                    $drive = New-PSDrive -Name "C_on_$machine" -PSProvider FileSystem -Root "\\$machine\c$" -Credential $cred -ErrorAction Stop
                }
                Write-Debug -Message "Drive '$($drive.Name)' created"
                $connectedMachines.Add($machine.Name, $drive)
            }
            catch
            {
                if (-not $FallbackToPSSession)
                {
                    Microsoft.PowerShell.Utility\Write-Error -Message "Could not create a SMB connection to '$machine' ('\\$machine\c$'). Files could not be copied." -TargetObject $machine -Exception $_.Exception
                    continue
                }

                $session = New-LabPSSession -ComputerName $machine -IgnoreAzureLabSources
                foreach ($p in $Path)
                {

                    $destination = if (-not $DestinationFolderPath)
                    {
                        '/'
                    }
                    else
                    {
                        $DestinationFolderPath
                    }
                    try
                    {
                        Send-Directory -SourceFolderPath $p -Session $session -DestinationFolderPath $destination
                        if ($PassThru)
                        {
                            $destination
                        }
                    }
                    catch
                    {
                        Write-Error -ErrorRecord $_
                    }
                }
            }
        }
        else
        {
            foreach ($p in $Path)
            {
                $session = New-LabPSSession -ComputerName $machine
                $destination = if (-not $DestinationFolderPath)
                {
                    Join-Path -Path / -ChildPath (Split-Path -Path $p -Leaf)
                }
                else
                {
                    Join-Path -Path $DestinationFolderPath -ChildPath (Split-Path -Path $p -Leaf)
                }

                Invoke-LabCommand -ComputerName $ComputerName -ActivityName Copy-LabFileItem -ScriptBlock {

                    Copy-Item -Path $p -Destination $destination -Recurse -Force

                } -NoDisplay -Variable (Get-Variable -Name p, destination)
            }

        }
    }

    Write-Verbose -Message "Copying the items '$($Path -join ', ')' to machines '$($connectedMachines.Keys -join ', ')'"

    foreach ($machine in $connectedMachines.GetEnumerator())
    {
        Write-Debug -Message "Starting copy job for machine '$($machine.Name)'..."

        if ($DestinationFolderPath)
        {
            $drive = "$($machine.Value):"
            $newDestinationFolderPath = Split-Path -Path $DestinationFolderPath -NoQualifier
            $newDestinationFolderPath = Join-Path -Path $drive -ChildPath $newDestinationFolderPath

            if (-not (Test-Path -Path $newDestinationFolderPath))
            {
                New-Item -ItemType Directory -Path $newDestinationFolderPath | Out-Null
            }
        }
        else
        {
            $newDestinationFolderPath = "$($machine.Value):\"
        }

        foreach ($p in $Path)
        {
            try
            {
                Copy-Item -Path $p -Destination $newDestinationFolderPath -Recurse -Force -ErrorAction Stop
                Write-Debug -Message '...finished'
                if ($PassThru)
                {
                    Join-Path -Path $DestinationFolderPath -ChildPath (Split-Path -Path $p -Leaf)
                }
            }
            catch
            {
                Write-Error -ErrorRecord $_
            }
        }

        $machine.Value | Remove-PSDrive
        Write-Debug -Message "Drive '$($drive.Name)' removed"
        Write-Verbose -Message "Files copied on to machine '$($machine.Name)'"
    }

    Write-LogFunctionExit
}
#endregion Copy-LabFileItem
