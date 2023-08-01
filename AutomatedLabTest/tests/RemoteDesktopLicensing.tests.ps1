Describe "[$((Get-Lab).Name)] RemoteDesktopLicensing" -Tag RemoteDesktopLicensing {
    Context "Role deployment successful" {
        It "[RemoteDesktopLicensing] Should return the correct amount of machines" {
            (Get-LabVm -Role RemoteDesktopLicensing).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'RemoteDesktopLicensing'}).Count
        }

        foreach ($vm in (Get-LabVM -Role RemoteDesktopLicensing))
        {
            It "[$vm] should be a RD license server" -TestCases @{
                vm = $vm
            } {
                $cb = Get-LabVM -Role RemoteDesktopConnectionBroker
                Invoke-LabCommand -NoDisplay -Computer $cb -ScriptBlock {(Get-RDLicenseConfiguration).LicenseServer} -PassThru | Should -Contain $vm.Fqdn
            }
        }
    }
}
