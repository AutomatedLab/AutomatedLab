Describe "[$($Lab.Name)] FailoverNode" -Tag FailoverNode {
    Context "Role deployment successful" {
        It "[FailoverNode] Should return the correct amount of machines" {
            (Get-LabVM -Role FailoverNode).Count | Should -Be $(Get-Lab).Machines.Where( { $_.Roles.Name -contains 'FailoverNode' }).Count
        }
    }

    foreach ($vm in (Get-LabVM -Role FailoverNode))
    {
        It "[$vm] Should be part of a cluster" -TestCases @{vm = $vm } {
            Invoke-LabCommand -ComputerName $vm -ScriptBlock { Get-Cluster -ErrorAction SilentlyContinue } -NoDisplay -PassThru | Should -Not -BeNullOrEmpty
        }
    }
}

