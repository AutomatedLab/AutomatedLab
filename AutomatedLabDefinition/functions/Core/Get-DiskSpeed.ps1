function Get-DiskSpeed
{
    [CmdletBinding()]
    param (
        [ValidatePattern('[a-zA-Z]')]
        [Parameter(Mandatory)]
        [string]$DriveLetter,

        [ValidateRange(1, 50)]
        [int]$Interations = 1
    )

    Write-LogFunctionEntry

    if (-not $labSources)
    {
        $labSources = Get-LabSourcesLocation
    }

    $IsReadOnly = Get-Partition -DriveLetter ($DriveLetter.TrimEnd(':')) | Select-Object -ExpandProperty IsReadOnly
    if ($IsReadOnly)
    {
        Write-ScreenInfo -Message "Drive $DriveLetter is read-only. Skipping disk speed test" -Type Warning

        $readThroughoutRandom = 0
        $writeThroughoutRandom = 0
    }
    else
    {
        Write-ScreenInfo -Message "Measuring speed of drive $DriveLetter" -Type Info

        $tempFileName = [System.IO.Path]::GetTempFileName()

        & "$labSources\Tools\WinSAT.exe" disk -ran -read -count $Interations -drive $DriveLetter -xml $tempFileName | Out-Null
        $readThroughoutRandom = (Select-Xml -Path $tempFileName -XPath '/WinSAT/Metrics/DiskMetrics/AvgThroughput').Node.'#text'

        & "$labSources\Tools\WinSAT.exe" disk -ran -write -count $Interations -drive $DriveLetter -xml $tempFileName | Out-Null
        $writeThroughoutRandom = (Select-Xml -Path $tempFileName -XPath '/WinSAT/Metrics/DiskMetrics/AvgThroughput').Node.'#text'

        Remove-Item -Path $tempFileName
    }

    $result = New-Object PSObject -Property ([ordered]@{
            ReadRandom  = $readThroughoutRandom
            WriteRandom = $writeThroughoutRandom
        })

    $result

    Write-LogFunctionExit
}
