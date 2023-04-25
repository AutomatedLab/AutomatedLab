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
