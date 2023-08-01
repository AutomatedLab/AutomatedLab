Describe "[$((Get-Lab).Name)] RemoteDesktopSessionHost" -Tag RemoteDesktopSessionHost {
    Context "Role deployment successful" {
        It "[RemoteDesktopSessionHost] Should return the correct amount of machines" {
            (Get-LabVm -Role RemoteDesktopSessionHost).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'RemoteDesktopSessionHost'}).Count
        }

        foreach ($vm in (Get-LabVM -Role RemoteDesktopSessionHost))
        {
            It "[$vm] should be a RD session host" -TestCases @{
                vm = $vm
            } {
                $cb = Get-LabVM -Role RemoteDesktopConnectionBroker
                (Invoke-LabCommand -NoDisplay -Computer $vm -Variable (Get-Variable -Name cb) -ScriptBlock {Get-RDServer -Role RDS-RD-SERVER -ConnectionBroker $cb.FQDN} -PassThru).Server | Should -Contain $vm.Fqdn
            }
        }
    }
}
