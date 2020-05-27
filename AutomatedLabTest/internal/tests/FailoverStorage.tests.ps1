param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) FailoverStorage" -Tag FailoverStorage {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role FailoverStorage).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'FailoverStorage'}).Count
        }
    }
}
