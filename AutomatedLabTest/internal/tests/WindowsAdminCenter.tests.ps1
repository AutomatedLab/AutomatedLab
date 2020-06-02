Describe "[$((Get-Lab).Name)] WindowsAdminCenter" -Tag WindowsAdminCenter {
    Context "Role deployment successful" {
        It "[$((Get-LabVM).Where({$_.PostInstallationActivity.Where({$_.IsCustomRole}).RoleName -contains 'WindowsAdminCenter'}))] URL accessible" {
            foreach ($vm in $((Get-LabVM).Where({$_.PostInstallationActivity.Where({$_.IsCustomRole}).RoleName -contains 'WindowsAdminCenter'})))
            {
                $role = $vm.PostInstallationActivity.Where({$_.IsCustomRole -and $_.RoleName -eq 'WindowsAdminCenter'})
                $port = 443
                if ($role.Properties.Port) { $port = $role.Properties.Port }
                $uri = "https://$($vm.Fqdn):$port"

                [ServerCertificateValidationCallback]::Ignore()

                $paramIwr = @{
                    Method      = 'GET'
                    Uri         = $uri
                    Credential  = $vm.GetCredential($(Get-Lab))
                    ErrorAction = 'Stop'
                }

                if ($PSEdition -eq 'Core' -and (Get-Command Invoke-RestMethod).Parameters.ContainsKey('SkipCertificateCheck'))
                {
                    $paramIwr.SkipCertificateCheck = $true
                }

                {Invoke-RestMethod @paramIwr} | Should -Not -Throw
            }
        }
    }
}
