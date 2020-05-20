param
(
    [Parameter(Mandatory)]
    [AutomatedLab.Lab]
    $Lab
)

Describe "$($Lab.Name) SharePoint2019" -Tag SharePoint2019 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role SharePoint2019).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'SharePoint2019'}).Count
        }
    }
}
