Describe "[$($Lab.Name)] DC Generic" -Tag RootDC, DC, FirstChildDC {

    Context "Role deployment successful" {
        It "[RootDC] Should return the correct amount of machines" {
            (Get-LabVM -Role ADDS).Count | Should -Be $(Get-Lab).Machines.Where( { $_.Roles.Name -contains 'RootDC' -or $_.Roles.Name -contains 'DC' -or $_.Roles.Name -contains 'FirstChildDC' }).Count
        }

        foreach ($vm in (Get-LabVM -Role ADDS))
        {
            It "$vm should have ADWS running" -TestCases @{vm = $vm } {
        
                Invoke-LabCommand -ComputerName $vm -ScriptBlock {
                    (Get-Service -Name ADWS).Status.ToString()
                } -PassThru -NoDisplay | Should -Be Running
            }
        }
        
        foreach ($vm in (Get-LabVM -Role ADDS))
        {
            It "$vm should respond to ADWS calls" -TestCases @{vm = $vm } {
            
                { Invoke-LabCommand -ComputerName $vm -ScriptBlock { Get-ADUser -Identity $env:USERNAME } -PassThru -NoDisplay } | Should -Not -Throw
            }
        }
    }
}

Describe "[$($Lab.Name)] RootDC specific" -Tag RootDC {
    
    foreach ($vm in (Get-LabVM -Role RootDC))
    {
        It "$(Get-LabVM -Role RootDC) should hold PDC emulator FSMO role" -TestCases @{vm = $vm } {
        
            Invoke-LabCommand -ComputerName $vm -ScriptBlock { (Get-ADDomain).PDCEmulator } -PassThru -NoDisplay | Should -Be $vm.FQDN
        }
    }
}

