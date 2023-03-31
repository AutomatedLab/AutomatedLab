Describe "[$((Get-Lab).Name)] ScomGateway" -Tag ScomGateway {
    Context "Role deployment successful" {
        It "[ScomGateway] Should return the correct amount of machines" {
            (Get-LabVm -Role ScomGateway).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'ScomGateway'}).Count
        }
    }
}
