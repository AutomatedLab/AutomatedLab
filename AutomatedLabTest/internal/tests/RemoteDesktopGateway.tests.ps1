Describe "[$((Get-Lab).Name)] RemoteDesktopGateway" -Tag RemoteDesktopGateway {
    Context "Role deployment successful" {
        It "[RemoteDesktopGateway] Should return the correct amount of machines" {
            (Get-LabVm -Role RemoteDesktopGateway).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'RemoteDesktopGateway'}).Count
        }

        foreach ($vm in (Get-LabVM -Role RemoteDesktopWebAccess))
        {
            It "[$vm] should be a RD connection broker" -TestCases @{
                vm = $vm
            } {
                $cb = Get-LabVM -Role RemoteDesktopConnectionBroker
                (Invoke-LabCommand -NoDisplay -Computer $cb -ScriptBlock {(Get-RDDeploymentGatewayConfiguration).GatewayExternalFqdn} -PassThru) | Should -Contain $vm.Fqdn
            }
        }
    }
}
