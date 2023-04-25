function Dismount-LWAzureIsoImage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification = "Not relevant, used in Invoke-LabCommand")]
    param
    (
        [Parameter(Mandatory, Position = 0)]
        [string[]]
        $ComputerName
    )

    Test-LabHostConnected -Throw -Quiet

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    Invoke-LabCommand -ComputerName $ComputerName -ActivityName "Dismounting ISO Images on Azure machines $($ComputerName -join ',')" -ScriptBlock {

        Get-Volume | 
        Where-Object DriveType -eq CD-ROM |
        ForEach-Object {
            Get-DiskImage -DevicePath $_.Path.TrimEnd('\') -ErrorAction SilentlyContinue
        } |
        ForEach-Object {
            Write-Verbose -Message "Dismounting '$($_.ImagePath)'"
            $_ | Dismount-DiskImage
        }

        Get-ChildItem -Path C:\ALMounts\*.iso -ErrorAction SilentlyContinue | Remove-Item
    } -NoDisplay
}
