Describe "[$($(Get-Lab).Name)] WebServer" -Tag WebServer {

    Context "Role deployment successful" {
        It "[WebServer] Should return the correct amount of machines" {
            (Get-LabVm -Role WebServer).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'WebServer'}).Count
        }

        It "[$(Get-LabVm -Role WebServer)] should have all required WebServer features installed" {
            $corefeatures = 'Web-WebServer','Web-Application-Proxy','Web-Health','Web-Performance','Web-Security','Web-App-Dev','Web-Ftp-Server','Web-Metabase','Web-Lgcy-Scripting','Web-WMI','Web-Scripting-Tools','Web-Mgmt-Service','Web-WHC'
            $fullfeatures = 'Web-Server'

            foreach ($vm in (Get-LabVm -Role WebServer))
            {
            $testedFeatures = if ($vm.OperatingSystem.Installation -eq 'Core') { $corefeatures} else {$fullfeatures}
            
                (Get-LabWindowsFeature -ComputerName $vm -FeatureName $testedFeatures -NoDisplay).Installed | Should -Not -Contain $false
            }
        }
    }
}

