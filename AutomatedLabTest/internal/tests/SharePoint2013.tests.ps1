Describe "[$($Lab.Name)] SharePoint2013" -Tag SharePoint2013 {
Context "Role deployment successful" {
        It "[SharePoint2013] Should return the correct amount of machines" {
            (Get-LabVm -Role SharePoint2013).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SharePoint2013'}).Count
        }

        foreach ($vm in (Get-LabVm -Role SharePoint2013))
        {
            It "[$vm] Should have SharePoint installed" -TestCases @{vm = $vm} {
                Invoke-LabCommand -ComputerName $vm -ScriptBlock { 
                    if (Get-Command -Name Get-Package -ErrorAction SilentlyContinue)
                    {
                        [bool](Get-Package -Provider programs -Name 'Microsoft SharePoint Server 2013' -ErrorAction SilentlyContinue)
                    }
                    else
                    {
                        Test-Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15"
                    }
                } -PassThru -NoDisplay | Should -Be $true
            }
        }
    }
}

