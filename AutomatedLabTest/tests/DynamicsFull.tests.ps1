Describe "[$((Get-Lab).Name)] DynamicsFull" -Tag DynamicsFull {
    Context "Role deployment successful" {
        It "[DynamicsFull] Should return the correct amount of machines" {
            (Get-LabVm -Role DynamicsFull).Count | Should -Be $(Get-Lab).Machines.Where( { $_.Roles.Name -contains 'DynamicsFull' }).Count
        }
        
        foreach ($vm in (Get-LabVM -Role DynamicsFull))
        {
            It "$vm should reach its Dynamics URL" -TestCases @{ vm = $vm } {

                Invoke-LabCommand -ComputerName $vm -ScriptBlock {
                    (Invoke-WebRequest -Method Get -Uri http://localhost:5555 -UseDefaultCredentials -UseBasicParsing -ErrorAction SilentlyContinue).StatusCode
                } -PassThru -NoDisplay | Should -Be 200
            }
        }
    }
}
