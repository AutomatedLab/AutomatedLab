Describe "[$((Get-Lab).Name)] DynamicsAdmin" -Tag DynamicsAdmin {
    Context "Role deployment successful" {
        It "[DynamicsAdmin] Should return the correct amount of machines" {
            (Get-LabVm -Role DynamicsAdmin).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'DynamicsAdmin'}).Count
        }
        
        foreach ($vm in (Get-LabVM -Role DynamicsAdmin))
        {
            It "$vm should reach its Dynamics URL" -TestCases @{ vm = $vm } {

                Invoke-LabCommand -ComputerName $vm -ScriptBlock {
                    (Invoke-WebRequest -Method Get -Uri http://localhost:5555 -UseDefaultCredentials -UseBasicParsing -ErrorAction SilentlyContinue).StatusCode
                } -PassThru -NoDisplay | Should -Be 200
            }
        }
    }
}
