param
(
    [Parameter(Mandatory)]
    [AutomatedLab.Lab]
    $Lab
)

Describe "$($Lab.Name) AzDevOps" -Tag AzDevOps {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role AzDevOps).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'AzDevOps'}).Count
        }
    }
}
