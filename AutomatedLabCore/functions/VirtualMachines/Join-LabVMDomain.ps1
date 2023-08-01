function Join-LabVMDomain
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [AutomatedLab.Machine[]]$Machine
    )

    Write-LogFunctionEntry

    #region Join-Computer
    function Join-Computer
    {
        [CmdletBinding()]

        param(
            [Parameter(Mandatory = $true)]
            [string]$DomainName,

            [Parameter(Mandatory = $true)]
            [string]$UserName,

            [Parameter(Mandatory = $true)]
            [string]$Password,

            [bool]$AlwaysReboot = $false,

            [string]$SshPublicKey
        )

        if ($IsLinux)
        {
            if ((Get-Command -Name realm -ErrorAction SilentlyContinue) -and (sudo realm list --name-only | Where {$_ -eq $DomainName}))
            {
                return $true
            }

            if (-not (Get-Command -Name realm -ErrorAction SilentlyContinue) -and (Get-Command -Name apt -ErrorAction SilentlyContinue))
            {
                sudo apt install -y realmd libnss-sss libpam-sss sssd sssd-tools adcli samba-common-bin oddjob oddjob-mkhomedir packagekit *>$null
            }
            elseif (-not (Get-Command -Name realm -ErrorAction SilentlyContinue) -and (Get-Command -Name dnf -ErrorAction SilentlyContinue))
            {
                sudo dnf install -y oddjob oddjob-mkhomedir sssd adcli krb5-workstation realmd samba-common samba-common-tools authselect-compat *>$null
            }
            elseif (-not (Get-Command -Name realm -ErrorAction SilentlyContinue) -and (Get-Command -Name yum -ErrorAction SilentlyContinue))
            {
                sudo yum install -y oddjob oddjob-mkhomedir sssd adcli krb5-workstation realmd samba-common samba-common-tools authselect-compat *>$null
            }

            if (-not (Get-Command -Name realm -ErrorAction SilentlyContinue))
            {
                # realm package missing or no known package manager
                return $false
            }

            $null = realm join --one-time-password "'$Password'" $DomainName
            $null = sudo sed -i "/^%wheel.*/a %$($DomainName.ToUpper())\\\\domain\\ admins ALL=(ALL) NOPASSWD: ALL" /etc/sudoers
            $null = sudo mkdir -p "/home/$($UserName)@$($DomainName)"
            $null = sudo chown -R "$($UserName)@$($DomainName):$($UserName)@$($DomainName)" /home/$($UserName)@$($DomainName) 2>$null
            if (-not [string]::IsNullOrWhiteSpace($SshPublicKey))
            {
                $null = sudo mkdir -p "/home/$($UserName)@$($DomainName)/.ssh"
                $null = echo "$($SshPublicKey -replace '\s*$')" | sudo tee --append /home/$($UserName)@$($DomainName)/.ssh/authorized_keys
                $null = sudo chmod 700 /home/$($UserName)@$($DomainName)/.ssh
                $null = sudo chmod 600 /home/$($UserName)@$($DomainName)/.ssh/authorized_keys 2>$null                
                $null = sudo restorecon -R /$($UserName)@$($DomainName)/.ssh 2>$null
            }

            return $true
        }

        $Credential = New-Object -TypeName PSCredential -ArgumentList $UserName, ($Password | ConvertTo-SecureString -AsPlainText -Force)

        try
        {
            if ([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name -eq $DomainName)
            {
                return $true
            }
        }
        catch
        {
            # Empty catch. If we are a workgroup member, it is domain join time.
        }

        try
        {
            Add-Computer -DomainName $DomainName -Credential $Credential -ErrorAction Stop -WarningAction SilentlyContinue
            $true
        }
        catch
        {
            if ($AlwaysReboot)
            {
                $false
                Start-Sleep -Seconds 1
                Restart-Computer -Force
            }
            else
            {
                Write-Error -Exception $_.Exception -Message $_.Exception.Message -ErrorAction Stop
            }
        }

        $logonName = "$DomainName\$UserName"

        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1 -Force | Out-Null
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value $logonName -Force | Out-Null
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value $Password -Force | Out-Null

        Start-Sleep -Seconds 1

        Restart-Computer -Force
    }
    #endregion

    $lab = Get-Lab
    $jobs = @()
    $startTime = Get-Date

    $machinesToJoin = $Machine | Where-Object SkipDeployment -eq $false
    Write-PSFMessage "Starting joining $($machinesToJoin.Count) machines to domains"
    foreach ($m in $machinesToJoin)
    {
        $domain = $lab.Domains | Where-Object Name -eq $m.DomainName
        $cred = $domain.GetCredential()

        Write-PSFMessage "Joining machine '$m' to domain '$domain'"
        $jobParameters = @{
            ComputerName = $m
            ActivityName = "DomainJoin_$m"
            ScriptBlock = (Get-Command Join-Computer).ScriptBlock
            UseLocalCredential = $true
            ArgumentList = $domain, $cred.UserName, $cred.GetNetworkCredential().Password
            AsJob = $true
            PassThru = $true
            NoDisplay = $true
        }

        if ($m.HostType -eq 'Azure')
        {
            $jobParameters.ArgumentList += $true
        }
        if ($m.SshPublicKey)
        {
            if ($jobParameters.ArgumentList.Count -eq 3)
            {
                $jobParameters.ArgumentList += $false
            }
            $jobParameters.ArgumentList += $m.SshPublicKey
        }
        $jobs += Invoke-LabCommand @jobParameters
    }

    if ($jobs)
    {
        Write-PSFMessage 'Waiting on jobs to finish'
        Wait-LWLabJob -Job $jobs -ProgressIndicator 15 -NoDisplay -NoNewLine

        Write-ProgressIndicatorEnd
        Write-ScreenInfo -Message 'Waiting for machines to restart' -NoNewLine
        Wait-LabVMRestart -ComputerName $machinesToJoin -ProgressIndicator 30 -NoNewLine -MonitoringStartTime $startTime
    }

    foreach ($m in $machinesToJoin)
    {
        $machineJob = $jobs | Where-Object -Property Name -EQ DomainJoin_$m
        $machineResult = $machineJob | Receive-Job -Keep -ErrorAction SilentlyContinue
        if (($machineJob).State -eq 'Failed' -or -not $machineResult)
        {
            Write-ScreenInfo -Message "$m failed to join the domain. Retrying on next restart" -Type Warning
            $m.HasDomainJoined = $false
        }
        else
        {
            $m.HasDomainJoined = $true
            if ($lab.DefaultVirtualizationEngine -eq 'Azure')
            {
                Enable-LabAutoLogon -ComputerName $m
            }
        }
    }

    Export-Lab

    Write-LogFunctionExit
}
