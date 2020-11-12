Describe "[$($Lab.Name)] SharePoint2019" -Tag SharePoint2019 {
Context "Role deployment successful" {
        It "[SharePoint2019] Should return the correct amount of machines" {
            (Get-LabVm -Role SharePoint2019).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SharePoint2019'}).Count
        }

        foreach ($vm in (Get-LabVm -Role SharePoint2019))
        {
            It "[$vm] Should have SharePoint installed" -TestCases @{vm = $vm} {
                Invoke-LabCommand -ComputerName $vm -ScriptBlock { 
                    if (Get-Command -Name Get-Package -ErrorAction SilentlyContinue)
                    {
                        [bool](Get-Package -Provider programs -Name 'Microsoft SharePoint Server 2019' -ErrorAction SilentlyContinue)
                    }
                    else
                    {
                        Test-Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16" # Same build number as 2016
                    }
                } -PassThru -NoDisplay | Should -Be $true
            }
        }
    }
}

