Describe "[$((Get-Lab).Name)] RemoteDesktopConnectionBroker" -Tag RemoteDesktopConnectionBroker {
    Context "Role deployment successful" {
        It "[RemoteDesktopConnectionBroker] Should return the correct amount of machines" {
            (Get-LabVm -Role RemoteDesktopConnectionBroker).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'RemoteDesktopConnectionBroker'}).Count
        }

        foreach ($vm in (Get-LabVM -Role RemoteDesktopConnectionBroker))
        {
            It "[$vm] should be a RD connection broker" -TestCases @{
                vm = $vm
            } {
                (Invoke-LabCommand -NoDisplay -Computer $vm -ScriptBlock {Get-RDServer -Role RDS-CONNECTION-BROKER} -PassThru).Server | Should -Contain $vm.Fqdn
            }
        }
    }
}
