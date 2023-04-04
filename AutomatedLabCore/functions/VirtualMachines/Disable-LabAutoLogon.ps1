function Disable-LabAutoLogon
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string[]]
        $ComputerName
    )

    Write-PSFMessage -Message "Disabling autologon on $($ComputerName.Count) machines"

    $Machines = Get-LabVm @PSBoundParameters

    Invoke-LabCommand -ActivityName "Disabling AutoLogon on $($ComputerName.Count) machines" -ComputerName $Machines -ScriptBlock {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -Value 0 -Type String -Force
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -Force -ErrorAction SilentlyContinue
    } -NoDisplay
}
