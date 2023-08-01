Describe "[$($Lab.Name)] FileServer" -Tag FileServer {
    Context "Role deployment successful" {
        It "[FileServer] Should return the correct amount of machines" {
            (Get-LabVM -Role FileServer).Count | Should -Be $(Get-Lab).Machines.Where( { $_.Roles.Name -contains 'FileServer' }).Count
        }

        foreach ($vm in (Get-LabVM -Role FileServer))
        {
            It "[$vm] should have all required WebServer features installed" -TestCases @{
                vm = $vm
            } {
                $testedFeatures = 'FileAndStorage-Services', 'File-Services ', 'FS-FileServer', 'FS-DFS-Namespace', 'FS-Resource-Manager', 'Print-Services', 'NET-Framework-Features', 'NET-Framework-45-Core'
            
                (Get-LabWindowsFeature -ComputerName $vm -FeatureName $testedFeatures -NoDisplay).Installed | Should -Not -Contain $false
            }
        }
    }
}

