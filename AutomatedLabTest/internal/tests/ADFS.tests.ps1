param
(
    [Parameter(Mandatory)]
    [AutomatedLab.Lab]
    $Lab
)

Describe "$($Lab.Name) ADFS" -Tag ADFS {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role ADFS).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'ADFS'}).Count
        }
    }
}
