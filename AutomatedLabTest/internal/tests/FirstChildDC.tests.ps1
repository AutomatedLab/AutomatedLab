param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) FirstChildDC" -Tag FirstChildDC {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role FirstChildDC).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'FirstChildDC'}).Count
        }
    }
}
