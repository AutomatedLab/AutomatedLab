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
    catch [Exception]
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
        [string]$Source,
		
        [Parameter(Mandatory = $true)]
        [string]$Destination,
		
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session
    )
	
    #Set-StrictMode -Version Latest
    $firstChunk = $true
	
    Write-Verbose "PSFileTransfer: Sending file $Source to $Destination on $($Session.ComputerName) ($([Math]::Round($chunkSize / 1MB, 2)) MB chunks)"
	
    $sourcePath = (Resolve-Path $Source -ErrorAction SilentlyContinue).Path
    if (-not $sourcePath)
    {
        Write-Error 'Source file could not be found'
        return
    }
	
    $sourceFileStream = [IO.File]::OpenRead($sourcePath)
	
    for ($position = 0; $position -lt $sourceFileStream.Length; $position += $chunkSize)
    {
        <#
                Write-Progress -Activity "Send file $Source to $Destination on $($Session.ComputerName)" `
                -Status 'Transmitting file' `
                -PercentComplete ($position / $sourceFileStream.Length * 100)
        #>
        
        $remaining = $sourceFileStream.Length - $position
        $remaining = [Math]::Min($remaining, $chunkSize)
		
        $chunk = New-Object -TypeName byte[] -ArgumentList $remaining
        [void]$sourceFileStream.Read($chunk, 0, $remaining)
		
        try
        {
            #Write-File -DestinationFile $Destination -Bytes $chunk -Erase $firstChunk
            Invoke-Command -Session $Session -ScriptBlock (Get-Command Write-File).ScriptBlock `
            -ArgumentList $Destination, $chunk, $firstChunk -ErrorAction Stop
        }
        catch [System.Exception]
        {
            Write-Error -Message 'Could not write destination file' -Exception $_.Exception
            return
        }
		
        $firstChunk = $false
    }
	
    $sourceFileStream.Close()
	
    Write-Verbose "PSFileTransfer: Finished sending file $Source"
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
	
    Set-StrictMode -Version Latest
    $firstChunk = $true
	
    Write-Verbose "PSFileTransfer: Receiving file $Source to $Destination from $($Session.ComputerName) ($([Math]::Round($chunkSize / 1MB, 2)) MB chunks)"
	
    $sourceLength = Invoke-Command -Session $Session -ScriptBlock (Get-Command Get-FileLength).ScriptBlock `
    -ArgumentList $Source -ErrorAction Stop
    #$sourceLength = Invoke-Command -Session $Session -ScriptBlock (Get-Command Read-File).ScriptBlock `
    #        -ArgumentList $Source, 0 -ErrorAction Stop
	
    for ($position = 0; $position -lt $sourceLength; $position += $chunkSize)
    {
        <#
                Write-Progress -Activity "Receive file $Source to $Destination from $($Session.ComputerName)" `
                -Status 'Transmitting file' `
                -PercentComplete ($position / $sourceLength * 100)
        #>
        
        $remaining = $sourceLength - $position
        $remaining = [Math]::Min($remaining, $chunkSize)
		
        try
        {
            #$chunk = Read-File -SourceFile $Source -Offset $position -Length $remaining
            $chunk = Invoke-Command -Session $Session -ScriptBlock (Get-Command Read-File).ScriptBlock `
            -ArgumentList $Source, $position, $chunkSize -ErrorAction Stop
        }
        catch [System.Exception]
        {
            Write-Error -Message 'Could not read destination file' -Exception $_.Exception
            return
        }
		
        Write-File -DestinationFile $Destination -Bytes $chunk.Bytes -Erase $firstChunk
		
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
	
    <#
            Write-Progress -Activity "Receive directory $Destination from $Source on $($Session.ComputerName)" `
            -Status 'Checking destination'
    #>
    
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
	
    <#
            Write-Progress -Activity "Receive directory $Destination from $Source on $($Session.ComputerName)" `
            -Status 'Reading remote content list'
    #>
    
    $remoteItems = Invoke-Command -Session $Session -ScriptBlock {
        param ($remoteDir)
		
        Get-ChildItem $remoteDir
    } -ArgumentList $remoteDir -ErrorAction Stop
    $position = 0
	
    foreach ($remoteItem in $remoteItems)
    {
        $itemSource = Join-Path -Path $Source -ChildPath $remoteItem.Name
        <#
                Write-Progress -Activity "Receive directory $Destination from $Source on $($Session.ComputerName)" `
                -Status "Copying $itemSource" `
                -PercentComplete ($position * 100 / @($remoteItems).Count)
        #>
        
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
    <#
            Write-Progress -Activity "Receive directory $Destination from $Source on $($Session.ComputerName)" `
            -Status 'Completed' -Completed
    #>
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
        $Destination,
		
        ## The session that represents the remote computer
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session
    )
	
    Write-Verbose "Send-Directory $($env:COMPUTERNAME): local source $Source, remote destination $Destination, session $($Session.ComputerName)"
	
    #Write-Progress -Activity "Send directory $Source to $Destination on $($Session.ComputerName)" -Status 'Checking source'
	
    $localDir = Get-Item $Source -ErrorAction Stop
    if (-not $localDir.PSIsContainer)
    {
        Send-File -Source $Source -Destination $Destination -Session $Session
        return
    }
	
    Invoke-Command -Session $Session -ScriptBlock {
        param ($Destination)
		
        if (-not (Test-Path $Destination))
        {
            $null = New-Item $Destination -ItemType Container -ErrorAction Stop
        }
        elseif (-not (Test-Path $Destination -PathType Container))
        {
            throw "$Destination exists and is not a directory"
        }
    } -ArgumentList $Destination -ErrorAction Stop
	
    <#
            Write-Progress -Activity "Send directory $Source to $Destination on $($Session.ComputerName)" `
            -Status 'Reading local content list'
    #>
    
    $localItems = Get-ChildItem $localDir -ErrorAction Stop
    $position = 0
	
    foreach ($localItem in $localItems)
    {
        $itemSource = Join-Path -Path $Source -ChildPath $localItem.Name
        <#
                Write-Progress -Activity "Send directory $Source to $Destination on $($Session.ComputerName)" `
                -Status "Copying $itemSource" `
                -PercentComplete ($position * 100 / @($localItems).Count)
        #>
        
        $itemDestination = Join-Path -Path $Destination -ChildPath $localItem.Name
        if ($localItem.PSIsContainer)
        {
            $null = Send-Directory -Source $itemSource -Destination $itemDestination -Session $Session
        }
        else
        {
            $null = Send-File -Source $itemSource -Destination $itemDestination -Session $Session
        }
        $position++
    }
    <#
            Write-Progress -Activity "Send directory $Source from $Destination on $($Session.ComputerName)" `
            -Status 'Completed' -Completed
    #>
}
#endregion Send-Directory
#endregion File Transfer Functions

function Write-File
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$DestinationFile,
		
        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes,
		
        [bool]$Erase
    )
	
    Write-Debug "Send-File $($env:COMPUTERNAME): writing $DestinationFile length $($Bytes.Length)"
	
    #Convert the destination path to a full filesytem path (to support relative paths)
    try
    {
        $DestinationFile = $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationFile)
    }
    catch [System.Exception]
    {
        throw New-Object -TypeName System.IO.FileNotFoundException -ArgumentList ('Could not set destination path', $_)
    }
	
    if ($Erase)
    {
        Remove-Item $DestinationFile -Force -ErrorAction SilentlyContinue
    }
	
    $destFileStream = [IO.File]::OpenWrite($DestinationFile)
    $destBinaryWriter = New-Object -TypeName System.IO.BinaryWriter -ArgumentList ($destFileStream)
	
    [void]$destBinaryWriter.Seek(0, 'End')
    $destBinaryWriter.Write($Bytes)
	
    $destBinaryWriter.Close()
    $destFileStream.Close()
	
    $Bytes = $null
    [GC]::Collect()
}

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
    catch [System.Exception]
    {
        throw New-Object -TypeName System.IO.FileNotFoundException
    }
	
    if (-not (Test-Path -Path $SourceFile))
    {
        throw 'Source file could not be found'
    }
	
    $sourceFileStream = [IO.File]::OpenRead($sourcePath)
	
    $chunk = New-Object -TypeName byte[] -ArgumentList $Length
    [void]$sourceFileStream.Seek($Offset, 'Begin')
    [void]$sourceFileStream.Read($chunk, 0, $Length)
	
    $sourceFileStream.Close()
	
    return @{ Bytes = $chunk }
}

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
    catch [System.Exception]
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

        [string]$DestinationFolder,
		
        [switch]$Recurse,
        
        [bool]$FallbackToPSSession = $true,
        
        [bool]$UseAzureLabSourcesOnAzureVm = $true
    )
	
    Write-LogFunctionEntry
	
    $machines = Get-LabMachine -ComputerName $ComputerName -ErrorAction Stop
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
                    $destination = if (-not $DestinationFolder)
                    {
                        Join-Path -Path C:\ -ChildPath (Split-Path -Path $p -Leaf)
                    }
                    else
                    {
                        Join-Path -Path $DestinationFolder -ChildPath (Split-Path -Path $p -Leaf)
                    }
                    Send-Directory -Source $p -Session $session -Destination $destination
                }
            }
        }
        else
        {
            foreach ($p in $Path)
            {
                $session = New-LabPSSession -ComputerName $machine
                $destination = if (-not $DestinationFolder)
                {
                    Join-Path -Path C:\ -ChildPath (Split-Path -Path $p -Leaf)
                }
                else
                {
                    Join-Path -Path $DestinationFolder -ChildPath (Split-Path -Path $p -Leaf)
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
        
        if ($DestinationFolder)
        {
            $drive = "$($machine.Value):"
            $DestinationFolder = Split-Path -Path $DestinationFolder -NoQualifier
            $DestinationFolder = Join-Path -Path $drive -ChildPath $DestinationFolder

            if (-not (Test-Path -Path $DestinationFolder))
            {
                mkdir -Path $DestinationFolder | Out-Null
            }
        }
        else
        {
            $DestinationFolder = "$($machine.Value):\"
        }

        Copy-Item -Path $Path -Destination $DestinationFolder -Recurse -Force
        Write-Debug '...finished'
		
        $machine.Value | Remove-PSDrive
        Write-Debug "Drive '$($drive.Name)' removed"
        Write-Verbose "Files copied on to machine '$($machine.Name)'"
    }
	
    Write-LogFunctionExit
}