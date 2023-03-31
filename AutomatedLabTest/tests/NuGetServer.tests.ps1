Describe "[$((Get-Lab).Name)] NuGetServer" -Tag NuGetServer {
    Context "Role deployment successful" {
        It "[NuGetServer] Should return the correct amount of machines" {
            (Get-LabVM).Where({$_.PreInstallationActivity.Where({$_.IsCustomRole}).RoleName -contains 'NuGetServer' -or $_.PostInstallationActivity.Where({$_.IsCustomRole}).RoleName -contains 'NuGetServer'})
        }
    }
}
