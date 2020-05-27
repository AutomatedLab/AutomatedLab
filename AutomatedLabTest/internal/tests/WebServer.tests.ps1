param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) WebServer" -Tag WebServer {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role WebServer).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'WebServer'}).Count
        }

        $corefeatures = 'Web-WebServer','Web-Application-Proxy','Web-Health','Web-Performance','Web-Security','Web-App-Dev','Web-Ftp-Server','Web-Metabase','Web-Lgcy-Scripting','Web-WMI','Web-Scripting-Tools','Web-Mgmt-Service','Web-WHC'
        $fullfeatures = 'Web-Server'
        foreach ($vm in (Get-LabVm -Role WebServer))
        {
            $testedFeatures = if ($vm.OperatingSystem.Installation -eq 'Core') { $corefeatures} else {$fullfeatures}
            It "$vm should have all required WebServer features installed" {
                (Get-LabWindowsFeature -ComputerName $vm -FeatureName $testedFeatures -NoDisplay).Installed | Should -Not -Contain $false
            }
        }
    }
}
