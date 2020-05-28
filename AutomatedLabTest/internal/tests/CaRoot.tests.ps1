Describe "[$($(Get-Lab).Name)] CaRoot" -Tag CaRoot {
Context "Role deployment successful" {
        It "[CaRoot] Should return the correct amount of machines" {
            (Get-LabVm -Role CaRoot).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'CaRoot'}).Count
        }

        foreach ($vm in (Get-LabVM -Role CaRoot))
        {
            It "$vm should have CertSvc running" {
                Invoke-LabCommand -ComputerName $vm -ScriptBlock {
                    (Get-Service -Name CertSvc).Status.ToString()
                } -PassThru -NoDisplay | Should -Be Running
            }
        }
    }
}

