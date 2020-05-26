param
(
    [Parameter(Mandatory)]
    [AutomatedLab.Lab]
    $Lab
)

Describe "$($Lab.Name) Routing" -Tag Routing {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role Routing).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'Routing'}).Count
        }
    }
}
