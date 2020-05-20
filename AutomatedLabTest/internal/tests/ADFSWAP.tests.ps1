param
(
    [Parameter(Mandatory)]
    [AutomatedLab.Lab]
    $Lab
)

Describe "$($Lab.Name) ADFSWAP" -Tag ADFSWAP {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role ADFSWAP).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'ADFSWAP'}).Count
        }
    }
}
