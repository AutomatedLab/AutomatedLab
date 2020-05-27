param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) Office2016" -Tag Office2016 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role Office2016).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'Office2016'}).Count
        }
    }
}
