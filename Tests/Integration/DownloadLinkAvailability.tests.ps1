BeforeDiscovery {
    [System.Collections.Generic.List[hashtable]] $links = Get-PSFConfig -Module AutomatedLab | Where-Object { $_.Value -like 'http*' -and $_.Name -notlike '*SharePoint*' } | ForEach-Object {
        @{
            Setting = $_.Name
            Uri     = $_.Value
        }
    }

    Get-PSFConfig -Module AutomatedLab | Where-Object Name -match 'SharePoint(2016|2019)Prerequisites' | ForEach-Object {
        $settingName = $_.Name
        $_.Value | Foreach-Object {
            $links.Add(@{
                    Setting = $settingName
                    Uri     = $_
                })
        }
    }
}

Describe 'Check links' {
    It 'Should be able to HEAD <Uri> for setting <Setting>' -ForEach $links {
        { $null = Invoke-RestMethod -Uri $Uri -Method Head -ErrorAction Stop } | Should -Not -Throw
    }
}
