param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) SharePoint2016" -Tag SharePoint2016 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role SharePoint2016).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'SharePoint2016'}).Count
        }
    }
}
