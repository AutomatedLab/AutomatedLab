Describe "[$((Get-Lab).Name)] DynamicsBackend" -Tag DynamicsBackend {
    Context "Role deployment successful" {
        It "[DynamicsBackend] Should return the correct amount of machines" {
            (Get-LabVm -Role DynamicsBackend).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'DynamicsBackend'}).Count
        }
        
        foreach ($vm in (Get-LabVM -Role DynamicsBackend))
        {
            It "$vm should reach its Dynamics URL" -TestCases @{ vm = $vm } {

                Invoke-LabCommand -ComputerName $vm -ScriptBlock {
                    (Invoke-WebRequest -Method Get -Uri http://localhost:5555 -UseDefaultCredentials -UseBasicParsing -ErrorAction SilentlyContinue).StatusCode
                } -PassThru -NoDisplay | Should -Be 200
            }
        }
    }
}
