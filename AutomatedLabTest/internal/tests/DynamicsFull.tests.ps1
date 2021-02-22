BeforeDiscovery {
    [hashtable[]] $fullCases = foreach ($vm in (Get-LabVm -Role DynamicsFull))
    {
        @{vm = $vm }
    }
}

Describe "[$((Get-Lab).Name)] DynamicsFull" -Tag DynamicsFull {
    Context "Role deployment successful" {
        It "[DynamicsFull] Should return the correct amount of machines" {
            (Get-LabVm -Role DynamicsFull).Count | Should -Be $(Get-Lab).Machines.Where( { $_.Roles.Name -contains 'DynamicsFull' }).Count
        }
        
        It "<vm> should reach its Dynamics URL" -TestCases $fullCases {
        
            Invoke-LabCommand -ComputerName $vm -ScriptBlock {
                (Invoke-WebRequest -Method Get -Uri http://localhost:5555 -UseDefaultCredentials -UseBasicParsing -ErrorAction SilentlyContinue).StatusCode
            } -PassThru -NoDisplay | Should -Be 200
        }
    }
}
