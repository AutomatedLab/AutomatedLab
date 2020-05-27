param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) Tfs2015" -Tag Tfs2015 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role Tfs2015).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'Tfs2015'}).Count
        }
    }
}
