Describe "[$((Get-Lab).Name)] RemoteDesktopWebAccess" -Tag RemoteDesktopWebAccess {
    Context "Role deployment successful" {
        It "[RemoteDesktopWebAccess] Should return the correct amount of machines" {
            (Get-LabVm -Role RemoteDesktopWebAccess).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'RemoteDesktopWebAccess'}).Count
        }

        foreach ($vm in (Get-LabVM -Role RemoteDesktopWebAccess))
        {
            It "[$vm] should be a RD connection broker" -TestCases @{
                vm = $vm
            } {
                $cb = Get-LabVM -Role RemoteDesktopConnectionBroker
                (Invoke-LabCommand -NoDisplay -Computer $vm -Variable (Get-Variable cb) -ScriptBlock {Get-RDServer -Role RDS-WEB-ACCESS -ConnectionBroker $cb.Fqdn} -PassThru).Server | Should -Contain $vm.Fqdn
            }
        }
    }
}
