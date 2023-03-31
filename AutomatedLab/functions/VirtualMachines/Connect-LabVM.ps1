function Connect-LabVM
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [switch]$UseLocalCredential
    )

    $machines = Get-LabVM -ComputerName $ComputerName -IncludeLinux
    $lab = Get-Lab

    foreach ($machine in $machines)
    {
        if ($UseLocalCredential)
        {
            $cred = $machine.GetLocalCredential()
        }
        else
        {
            $cred = $machine.GetCredential($lab)
        }

        if ($machine.OperatingSystemType -eq 'Linux')
        {
            $sshBinary = Get-Command ssh.exe -ErrorAction SilentlyContinue
            if (-not $sshBinary) { Get-ChildItem $labsources\Tools\OpenSSH -Filter ssh.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 }

            if (-not $sshBinary -and -not (Get-LabConfigurationItem -Name DoNotPrompt))
            {
                $download = Read-Choice -ChoiceList 'No','Yes' -Caption 'Download Win32-OpenSSH' -Message 'OpenSSH is necessary to connect to Linux VMs. Would you like us to download Win32-OpenSSH for you?' -Default 1

                if ([bool]$download)
                {
                    $downloadUri = Get-LabConfigurationItem -Name OpenSshUri
                    $downloadPath = Join-Path ([System.IO.Path]::GetTempPath()) -ChildPath openssh.zip
                    $targetPath = "$labsources\Tools\OpenSSH"
                    Get-LabInternetFile -Uri $downloadUri -Path $downloadPath

                    Microsoft.PowerShell.Archive\Expand-Archive -Path $downloadPath -DestinationPath $targetPath -Force
                    $sshBinary = Get-ChildItem $labsources\Tools\OpenSSH -Filter ssh.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                }
            }

            if ($UseLocalCredential)
            {
                $arguments = '-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l {0} {1}' -f $cred.UserName,$machine
            }
            else
            {
                $arguments = '-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l {0}@{2} {1}' -f $cred.UserName,$machine,$cred.GetNetworkCredential().Domain
            }

            Start-Process -FilePath $sshBinary.FullPath -ArgumentList $arguments
            return
        }

        if ($machine.HostType -eq 'Azure')
        {
            $cn = Get-LWAzureVMConnectionInfo -ComputerName $machine
            $cmd = 'cmdkey.exe /add:"TERMSRV/{0}" /user:"{1}" /pass:"{2}"' -f $cn.DnsName, $cred.UserName, $cred.GetNetworkCredential().Password
            Invoke-Expression $cmd | Out-Null
            mstsc.exe "/v:$($cn.DnsName):$($cn.RdpPort)" /f

            Start-Sleep -Seconds 5 #otherwise credentials get deleted too quickly

            $cmd = 'cmdkey /delete:TERMSRV/"{0}"' -f $cn.DnsName
            Invoke-Expression $cmd | Out-Null
        }
        elseif (Get-LabConfigurationItem -Name SkipHostFileModification)
        {
            $cmd = 'cmdkey.exe /add:"TERMSRV/{0}" /user:"{1}" /pass:"{2}"' -f $machine.IpAddress.ipaddress.AddressAsString, $cred.UserName, $cred.GetNetworkCredential().Password
            Invoke-Expression $cmd | Out-Null
            mstsc.exe "/v:$($machine.IpAddress.ipaddress.AddressAsString)" /f

            Start-Sleep -Seconds 1 #otherwise credentials get deleted too quickly

            $cmd = 'cmdkey /delete:TERMSRV/"{0}"' -f $machine.IpAddress.ipaddress.AddressAsString
            Invoke-Expression $cmd | Out-Null
        }
        else
        {
            $cmd = 'cmdkey.exe /add:"TERMSRV/{0}" /user:"{1}" /pass:"{2}"' -f $machine.Name, $cred.UserName, $cred.GetNetworkCredential().Password
            Invoke-Expression $cmd | Out-Null
            mstsc.exe "/v:$($machine.Name)" /f

            Start-Sleep -Seconds 1 #otherwise credentials get deleted too quickly

            $cmd = 'cmdkey /delete:TERMSRV/"{0}"' -f $machine.Name
            Invoke-Expression $cmd | Out-Null
        }
    }
}
