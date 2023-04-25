Describe "[$($Lab.Name)] ConfigurationManager" -Tag ConfigurationManager {
    Context "Role deployment successful" {
        It "[ConfigurationManager] Should return the correct amount of machines" {
            (Get-LabVM -Role ConfigurationManager).Count | Should -Be $(Get-Lab).Machines.Where( { $_.Roles.Name -contains 'ConfigurationManager' }).Count
        }
    }

    foreach ($vm in (Get-LabVM -Role ConfigurationManager))
    {
        It "[$vm] Should locate CM site" -TestCases @{vm = $vm } {
            $cim = New-LabCimSession -ComputerName $vm
            $role = $vm.Roles.Where( { $_.Name -eq 'ConfigurationManager' })
            $siteCode = if ($role.Properties.ContainsKey('SiteCode')) { $role.Properties.SiteCode } else { 'AL1' }
            $Query = "SELECT * FROM SMS_Site WHERE SiteCode='{0}'" -f $siteCode
            $Namespace = "ROOT/SMS/site_{0}" -f $siteCode
            Get-CimInstance -Namespace $Namespace -Query $Query -ErrorAction "SilentlyContinue" -CimSession $cim | Should -Not -BeNullOrEmpty
        }
    }
}
