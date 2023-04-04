function Enable-LabAutoLogon
{
    [CmdletBinding()]
    [Alias('Set-LabAutoLogon')]
    param
    (
        [Parameter()]
        [string[]]
        $ComputerName
    )

    Write-PSFMessage -Message "Enabling autologon on $($ComputerName.Count) machines"

    $machines = Get-LabVm @PSBoundParameters

    foreach ($machine in $machines)
    {
        $parameters = @{
            UserName = $machine.InstallationUser.UserName
            Password = $machine.InstallationUser.Password
        }

        if ($machine.IsDomainJoined)
        {
            if ($machine.Roles.Name -contains 'RootDC' -or $machine.Roles.Name -contains 'FirstChildDC' -or $machine.Roles.Name -contains 'DC')
            {
                $isAdReady = Test-LabADReady -ComputerName $machine
                
                if ($isAdReady)
                {
                    $parameters['DomainName'] = $machine.DomainName
                }
                else
                {
                    $parameters['DomainName'] = $machine.Name
                }
            }
            else
            {
                $parameters['DomainName'] = $machine.DomainName
            }
        }
        else
        {
            $parameters['DomainName'] = $machine.Name
        }

        Invoke-LabCommand -ActivityName "Enabling AutoLogon on $($machine.Name)" -ComputerName $machine.Name -ScriptBlock {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -Value 1 -Type String -Force
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoLogonCount -Value 9999 -Type DWORD -Force
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultDomainName -Value $parameters.DomainName -Type String -Force
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -Value $parameters.Password -Type String -Force
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUserName -Value $parameters.UserName -Type String -Force
        } -Variable (Get-Variable parameters) -DoNotUseCredSsp -NoDisplay
    }
}
