param
(
    [Parameter(Mandatory)]
    [AutomatedLab.Lab]
    $Lab
)

Describe "$($Lab.Name) Tfs2018" -Tag Tfs2018 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role Tfs2018).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'Tfs2018'}).Count
        }
    }
}
