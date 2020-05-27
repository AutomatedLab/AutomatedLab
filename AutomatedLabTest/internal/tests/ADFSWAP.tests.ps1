param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) ADFSWAP" -Tag ADFSWAP {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role ADFSWAP).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'ADFSWAP'}).Count
        }
    }
}
