BeforeDiscovery {
    [hashtable[]] $frontendCases = foreach ($vm in (Get-LabVm -Role DynamicsFrontend))
    {
        @{vm = $vm }
    }
}

Describe "[$((Get-Lab).Name)] DynamicsFrontend" -Tag DynamicsFrontend {
    Context "Role deployment successful" {
        It "[DynamicsFrontend] Should return the correct amount of machines" {
            (Get-LabVm -Role DynamicsFrontend).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'DynamicsFrontend'}).Count
        }
        
        It "<vm> should reach its Dynamics URL" -TestCases $frontendCases {
        
            Invoke-LabCommand -ComputerName $vm -ScriptBlock {
                (Invoke-WebRequest -Method Get -Uri http://localhost:5555 -UseDefaultCredentials -UseBasicParsing -ErrorAction SilentlyContinue).StatusCode
            } -PassThru -NoDisplay | Should -Be 200
        }
    }
}
