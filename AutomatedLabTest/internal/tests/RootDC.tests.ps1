Describe "[$($(Get-Lab).Name)] DC Generic" -Tag RootDC,DC,FirstChildDC {

    Context "Role deployment successful" {
        It "[RootDC] Should return the correct amount of machines" {
            (Get-LabVm -Role ADDS).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'RootDC' -or $_.Roles.Name -contains 'DC' -or $_.Roles.Name -contains 'FirstChildDC'}).Count
        }

        It "$(Get-LabVM -Role ADDS) should have ADWS running" {
            foreach ($vm in (Get-LabVM -Role ADDS))
        {
            Invoke-LabCommand -ComputerName $vm -ScriptBlock {
                (Get-Service -Name ADWS).Status.ToString()
            } -PassThru -NoDisplay | Should -Be Running
        }
        }
        
        It "$(Get-LabVM -Role ADDS) should respond to ADWS calls" {
            foreach ($vm in (Get-LabVM -Role ADDS))
            {
                {Invoke-LabCommand -ComputerName $vm -ScriptBlock { Get-ADUser -Identity $env:USERNAME } -PassThru -NoDisplay } | Should -Not -Throw
            }
        }
    }
}

Describe "[$($(Get-Lab).Name)] RootDC specific" -Tag RootDC {
    
    It "$(Get-LabVm -Role RootDC) should hold PDC emulator FSMO role" {
        foreach ($vm in (Get-LabVm -Role RootDC))
        {
            Invoke-LabCommand -ComputerName $vm -ScriptBlock { (Get-ADDomain).PDCEmulator} -PassThru -NoDisplay | Should -Be $vm.FQDN
        }
    }
}

