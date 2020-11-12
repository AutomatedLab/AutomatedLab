Describe "[$($Lab.Name)] CaSubordinate" -Tag CaSubordinate {
Context "Role deployment successful" {
        It "[CaSubordinate] Should return the correct amount of machines" {
            (Get-LabVm -Role CaSubordinate).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'CaSubordinate'}).Count
        }

        foreach ($vm in (Get-LabVM -Role CaSubordinate))
        {
            It "[$vm] should have CertSvc running" -TestCases @{vm = $vm} {
                Invoke-LabCommand -ComputerName $vm -ScriptBlock {
                    (Get-Service -Name CertSvc).Status.ToString()
                } -PassThru -NoDisplay | Should -Be Running
            }

            It "[$vm] Should be discoverable" {
                Invoke-LabCommand -ComputerName $vm -Function (Get-Command Find-CertificateAuthority) -ScriptBlock {
                    Find-CertificateAuthority -DomainName ([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name)
                } -PassThru -NoDisplay | Should -Match "$($vm.Name)\\\w+"
            }
        }
    }
}

