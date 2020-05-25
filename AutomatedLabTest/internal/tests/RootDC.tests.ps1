param
(
    [Parameter(Mandatory)]
    [AutomatedLab.Lab]
    $Lab
)

Describe "$($Lab.Name) DC Generic" -Tag RootDC,DC,FirstChildDC {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role ADDS).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'RootDC' -or $_.Roles.Name -contains 'DC' -or $_.Roles.Name -contains 'FirstChildDC'}).Count
        }

        foreach ($vm in (Get-LabVM -Role ADDS))
        {
            It "$vm should have ADWS running" {
                Invoke-LabCommand -ComputerName $vm -ScriptBlock {
                    (Get-Service -Name ADWS).Status.ToString()
                } -PassThru -NoDisplay | Should -Be Running
            }
            
            It "$vm should resond to ADWS calls" {
                {
                    Invoke-LabCommand -ComputerName $vm -ScriptBlock {
                        Get-ADUser -Identity $env:USERNAME
                } -PassThru -NoDisplay } | Should -Not -Throw
            }
        }
    }
}

Describe "$($Lab.Name) RootDC specific" -Tag RootDC {
    foreach ($vm in (Get-LabVm -Role RootDC))
    {
        It "$vm should hold PDC emulator FSMO role" {
            Invoke-LabCommand -ComputerName $vm -ScriptBlock { (Get-ADDomain).PDCEmulator} -PassThru -NoDisplay | Should -Be $vm.FQDN
        }
    }
}
