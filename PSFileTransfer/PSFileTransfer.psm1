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
	
    Write-Verbose "PSFileTransfer: Sending file $SourceFilePath to $DestinationFolderPath on $($Session.ComputerName) ($([Math]::Round($chunkSize / 1MB, 2)) MB chunks)"
	
    $sourcePath = (Resolve-Path $SourceFilePath -ErrorAction SilentlyContinue).Path
    if (-not $sourcePath)
    {
        Write-Error 'Source file could not be found'
        return
    }
	
    $sourceFileStream = [IO.File]::OpenRead($sourcePath)
	
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
	
    Write-Verbose "PSFileTransfer: Finished sending file $SourceFilePath"
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
        [string]$Source,
		
        [Parameter(Mandatory = $true)]
        [string]$Destination,
		
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession] $Session
    )

    $firstChunk = $true
	
    Write-Verbose "PSFileTransfer: Receiving file $Source to $Destination from $($Session.ComputerName) ($([Math]::Round($chunkSize / 1MB, 2)) MB chunks)"
	
    $sourceLength = Invoke-Command -Session $Session -ScriptBlock (Get-Command Get-FileLength).ScriptBlock `
    -ArgumentList $Source -ErrorAction Stop
	
    for ($position = 0; $position -lt $sourceLength; $position += $chunkSize)
    {
        
        $remaining = $sourceLength - $position
        $remaining = [Math]::Min($remaining, $chunkSize)
		
        try
        {
            $chunk = Invoke-Command -Session $Session -ScriptBlock (Get-Command Read-File).ScriptBlock `
            -ArgumentList $Source, $position, $chunkSize -ErrorAction Stop
        }
        catch
        {
            Write-Error -Message 'Could not read destination file' -Exception $_.Exception
            return
        }
		
        Write-File -DestinationFullName $Destination -Bytes $chunk.Bytes -Erase $firstChunk
		
        $firstChunk = $false
    }
	
    Write-Verbose "PSFileTransfer: Finished receiving file $Source"
}
#endregion Receive-File

#region Receive-Directory
function Receive-Directory
{
    param (
        ## The target path on the remote computer
        [Parameter(Mandatory = $true)]
        $Source,
		
        ## The path on the local computer
        [Parameter(Mandatory = $true)]
        $Destination,
		
        ## The session that represents the remote computer
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession] $Session
    )
    Write-Verbose "Receive-Directory $($env:COMPUTERNAME): remote source $Source, local destination $Destination, session $($Session.ComputerName)"
    
    $remoteDir = Invoke-Command -Session $Session -ScriptBlock {
        param ($Source)
		
        Get-Item $Source
    } -ArgumentList $Source -ErrorAction Stop
	
    if (-not $remoteDir.PSIsContainer)
    {
        Receive-File $Source $Destination $Session
    }
	
    if (-not (Test-Path $Destination))
    {
        New-Item $Destination -ItemType Container -ErrorAction Stop
    }
    elseif (-not (Test-Path $Destination -PathType Container))
    {
        throw "$Destination exists and is not a directory"
    }
    
    $remoteItems = Invoke-Command -Session $Session -ScriptBlock {
        param ($remoteDir)
		
        Get-ChildItem $remoteDir
    } -ArgumentList $remoteDir -ErrorAction Stop
    $position = 0
	
    foreach ($remoteItem in $remoteItems)
    {
        $itemSource = Join-Path -Path $Source -ChildPath $remoteItem.Name
        
        $itemDestination = Join-Path -Path $Destination -ChildPath $remoteItem.Name
        if ($remoteItem.PSIsContainer)
        {
            $null = Receive-Directory -Source $itemSource -Destination $itemDestination -Session $Session
        }
        else
        {
            $null = Receive-File -Source $itemSource -Destination $itemDestination -Session $Session
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
        $Source,
		
        ## The target path on the remote computer
        [Parameter(Mandatory = $true)]
        $DestinationFolderPath,
		
        ## The session that represents the remote computer
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session
    )
    
    $isCalledRecursivly = (Get-PSCallStack | Where-Object Command -eq $MyInvocation.InvocationName | Measure-Object | Select-Object -ExpandProperty Count) -gt 1
    if (-not $DestinationFolderPath.EndsWith('\')) { $DestinationFolderPath = $DestinationFolderPath + '\' }
    
    if (-not $isCalledRecursivly)
    {
        $initialDestinationFolderPath = $DestinationFolderPath
        $initialSource = $Source
        $initialSourceParent = Split-Path -Path $initialSource -Parent
    }
	
    Write-Verbose "Send-Directory $($env:COMPUTERNAME): local source $Source, remote destination $DestinationFolderPath, session $($Session.ComputerName)"
	
    $localDir = Get-Item $Source -ErrorAction Stop
    if (-not $localDir.PSIsContainer)
    {
        Send-File -SourceFilePath $Source -DestinationFolderPath $DestinationFolderPath -Session $Session -Force
        return
    }
	
    Invoke-Command -Session $Session -ScriptBlock {
        param ($DestinationPath)
		
        if (-not (Test-Path $DestinationPath))
        {
            $null = mkdir -Path $DestinationPath -ErrorAction Stop
        }
        elseif (-not (Test-Path $DestinationPath -PathType Container))
        {
            throw "$DestinationPath exists and is not a directory"
        }
    } -ArgumentList $DestinationFolderPath -ErrorAction Stop
    
    $localItems = Get-ChildItem -Path $localDir -ErrorAction Stop
    $position = 0
	
    foreach ($localItem in $localItems)
    {
        $itemSource = Join-Path -Path $Source -ChildPath $localItem.Name
        $newDestinationFolder = $itemSource.Replace($initialSourceParent, $initialDestinationFolderPath)
        
        if ($localItem.PSIsContainer)
        {
            $null = Send-Directory -Source $itemSource -DestinationFolderPath $newDestinationFolder -Session $Session
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
	
    Write-Debug "Send-File $($env:COMPUTERNAME): writing $DestinationFullName length $($Bytes.Length)"
    $VerbosePreference=2
	
    #Convert the destination path to a full filesytem path (to support relative paths)
    try
    {
        $DestinationFullName = $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationFullName)
    }
    catch
    {
        throw New-Object -TypeName System.IO.FileNotFoundException -ArgumentList ('Could not set destination path', $_)
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
            Write-Verbose "Force is set and destination folder '$parentPath' does not exist, creating it."
            mkdir -Path $parentPath -Force | Out-Null
        }
    }
	
    $destFileStream = [IO.File]::OpenWrite($DestinationFullName)
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
	
    $sourceFileStream = [IO.File]::OpenRead($sourcePath)
	
    $chunk = NeFileject -TypeName byte[] -ArgumentList $Fength
    [void]$sourceFileStream.Seek($Offset, 'Begin')
    [void]$sourceFileStream.Read($chunk, 0, $Length)
	
    $sourceFileStream.Close()
	
    return @{ Bytes = $chunk }
}
#endregion Read-File

function Get-FileLength
{
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$File
    )
	
    try
    {
        $File = $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($File)
    }
    catch
    {
        throw $_
    }
	
    (Get-Item -Path $File).Length
}

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
        
        [bool]$UseAzureLabSourcesOnAzureVm = $true
    )
	
    Write-LogFunctionEntry
	
    $machines = Get-LabVM -ComputerName $ComputerName -ErrorAction Stop
    $connectedMachines = @{ }
	
    foreach ($machine in $machines)
    {
        $cred = $machine.GetCredential((Get-Lab))
		
        if ($machine.HostType -eq 'HyperV' -or
        (-not $UseAzureLabSourcesOnAzureVm -and $machine.HostType -eq 'Azure'))
        {
            try
            {
                $drive = New-PSDrive -Name "C_on_$machine" -PSProvider FileSystem -Root "\\$machine\c$" -Credential $cred -ErrorAction Stop
                Write-Debug "Drive '$($drive.Name)' created"
                $connectedMachines.Add($machine.Name, $drive)
            }
            catch
            {
                if (-not $FallbackToPSSession)
                {
                    Microsoft.PowerShell.Utility\Write-Error -Message "Could not create a SMB connection to '$machine' ('\\$machine\c$'). Files could not be copied." -TargetObject $machine -Exception $_.Exception
                    continue
                }
            
                foreach ($p in $Path)
                {
                    $session = New-LabPSSession -ComputerName $machine
                    $destination = if (-not $DestinationFolderPath)
                    {
                        Join-Path -Path C:\ -ChildPath (Split-Path -Path $p -Leaf)
                    }
                    else
                    {
                        Join-Path -Path $DestinationFolderPath -ChildPath (Split-Path -Path $p -Leaf)
                    }
                    Send-Directory -Source $p -Session $session -DestinationFolderPath $destination
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
                    Join-Path -Path C:\ -ChildPath (Split-Path -Path $p -Leaf)
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
        Write-Debug "Starting copy job for machine '$($machine.Name)'..."
        
        if ($DestinationFolderPath)
        {
            $drive = "$($machine.Value):"
            $DestinationFolderPath = Split-Path -Path $DestinationFolderPath -NoQualifier
            $DestinationFolderPath = Join-Path -Path $drive -ChildPath $DestinationFolderPath

            if (-not (Test-Path -Path $DestinationFolderPath))
            {
                mkdir -Path $DestinationFolderPath | Out-Null
            }
        }
        else
        {
            $DestinationFolderPath = "$($machine.Value):\"
        }

        Copy-Item -Path $Path -Destination $DestinationFolderPath -Recurse -Force
        Write-Debug '...finished'
		
        $machine.Value | Remove-PSDrive
        Write-Debug "Drive '$($drive.Name)' removed"
        Write-Verbose "Files copied on to machine '$($machine.Name)'"
    }
	
    Write-LogFunctionExit
}