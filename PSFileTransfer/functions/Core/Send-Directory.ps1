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
