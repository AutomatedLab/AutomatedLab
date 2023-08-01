function Test-LabAutoLogon
{
    [OutputType([System.Collections.Hashtable])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]
        $ComputerName,

        [switch]
        $TestInteractiveLogonSession
    )

    Write-PSFMessage -Message "Testing autologon on $($ComputerName.Count) machines"

    [void]$PSBoundParameters.Remove('TestInteractiveLogonSession')
    $machines = Get-LabVM @PSBoundParameters
    $returnValues = @{}

    foreach ($machine in $machines)
    {
        $parameters = @{
            Username = $machine.InstallationUser.UserName
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

        $settings = Invoke-LabCommand -ActivityName "Testing AutoLogon on $($machine.Name)" -ComputerName $machine.Name -ScriptBlock {
            $values = @{}
            $values['AutoAdminLogon'] = try { (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction Stop).AutoAdminLogon } catch { }
            $values['DefaultDomainName'] = try { (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction Stop).DefaultDomainName } catch { }
            $values['DefaultUserName'] = try { (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction Stop).DefaultUserName } catch { }
            $values['DefaultPassword'] = try { (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction Stop).DefaultPassword } catch { }
            if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)
            {
                $values['LoggedOnUsers'] = (Get-CimInstance -ClassName win32_logonsession -Filter 'logontype=2' | Get-CimAssociatedInstance -Association Win32_LoggedOnUser).Caption
            }
            else
            {
                $values['LoggedOnUsers'] = (Get-WmiObject -Class Win32_LogonSession -Filter 'LogonType=2').GetRelationships('Win32_LoggedOnUser').Antecedent |
                ForEach-Object {
                    # For deprecated OS versions...
                    # Output is convoluted vs the CimInstance variant: \\.\root\cimv2:Win32_Account.Domain="contoso",Name="Install"
                    $null = $_ -match 'Domain="(?<Domain>.+)",Name="(?<Name>.+)"'
                    -join ($Matches.Domain, '\', $Matches.Name)
                } | Select-Object -Unique
            }

            $values
        } -PassThru -NoDisplay

        Write-PSFMessage -Message ('Encountered the following values on {0}:{1}' -f $machine.Name, ($settings | Out-String))

        if ($settings.AutoAdminLogon -ne 1 -or
            $settings.DefaultDomainName -ne $parameters.DomainName -or
            $settings.DefaultUserName -ne $parameters.Username -or
        $settings.DefaultPassword -ne $parameters.Password)
        {
            $returnValues[$machine.Name] = $false
            continue
        }


        if ($TestInteractiveLogonSession)
        {
            $interactiveSessionUserName = '{0}\{1}' -f ($parameters.DomainName -split '\.')[0], $parameters.Username

            if ($settings.LoggedOnUsers -notcontains $interactiveSessionUserName)
            {
                $returnValues[$Machine.Name] = $false
                continue
            }
        }

        $returnValues[$machine.Name] = $true
    }

    return $returnValues
}
