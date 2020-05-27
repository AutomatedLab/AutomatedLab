param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) Tfs2017" -Tag Tfs2017 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role Tfs2017).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'Tfs2017'}).Count
        }
    }
}
