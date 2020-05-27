param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) Office2013" -Tag Office2013 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role Office2013).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'Office2013'}).Count
        }
    }
}
