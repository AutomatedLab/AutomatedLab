param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) FailoverNode" -Tag FailoverNode {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role FailoverNode).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'FailoverNode'}).Count
        }
    }
}
