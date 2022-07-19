Describe "[$((Get-Lab).Name)] LabBuilder" -Tag LabBuilder {
    Context "Role deployment successful" {
        It "[LabBuilder] Should return the correct amount of machines" {
            (Get-LabVM).Where({$_.PreInstallationActivity.Where({$_.IsCustomRole}).RoleName -contains 'LabBuilder' -or $_.PostInstallationActivity.Where({$_.IsCustomRole}).RoleName -contains 'LabBuilder'})
        }

        It '[LabBuilder] API endpoint /Lab accessible' {
            $credential = (Get-LabVm -ComputerName NestedBuilder).GetCredential((Get-lab))
            {$allLabs = Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab -Credential $credential -ErrorAction Stop} | Should -Not -Throw
        }
    }
}
