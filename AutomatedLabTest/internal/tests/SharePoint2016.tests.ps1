Describe "[$($Lab.Name)] SharePoint2016" -Tag SharePoint2016 {
Context "Role deployment successful" {
        It "[SharePoint2016] Should return the correct amount of machines" {
            (Get-LabVm -Role SharePoint2016).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SharePoint2016'}).Count
        }

        foreach ($vm in (Get-LabVm -Role SharePoint2016))
        {
            It "[$vm] Should have SharePoint installed" -TestCases @{vm = $vm} {
                Invoke-LabCommand -ComputerName $vm -ScriptBlock { 
                    if (Get-Command -Name Get-Package -ErrorAction SilentlyContinue)
                    {
                        [bool](Get-Package -Provider programs -Name 'Microsoft SharePoint Server 2016' -ErrorAction SilentlyContinue)
                    }
                    else
                    {
                        Test-Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16"
                    }
                } -PassThru -NoDisplay | Should -Be $true
            }
        }
    }
}

