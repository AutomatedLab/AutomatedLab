function Invoke-LabPester {
    [CmdletBinding(DefaultParameterSetName = 'ByLab')]
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'ByLab', ValueFromPipeline)]
        [AutomatedLab.Lab]
        $Lab,

        [Parameter(Mandatory, ParameterSetName = 'ByName', ValueFromPipeline)]
        [string]
        $LabName,

        [ValidateSet('None', 'Normal', 'Detailed' , 'Diagnostic')]
        $Show = 'None',

        [switch]
        $PassThru,

        [string]
        $OutputFile
    )

    process {
        if (-not $Lab) {
            $Lab = Import-Lab -Name $LabName -ErrorAction Stop -NoDisplay -NoValidation -PassThru
        }

        $global:pesterLab = $Lab # No parameters in Pester v5 yet
        $configuration = [PesterConfiguration]::Default
        $config_paths = @() # Setup the array to pass to $Configuration.Run.Path
        $config_paths += Join-Path -Path $PSCmdlet.MyInvocation.MyCommand.Module.ModuleBase -ChildPath 'tests' # This is for the built-in Roles
        $configuration.Run.PassThru = $PassThru.IsPresent
        [string[]]$tags = 'General'
        
        if ($Lab.Machines.Roles.Name) {
            $tags += $Lab.Machines.Roles.Name
        }
        if ($Lab.Machines.PostInstallationActivity | Where-Object IsCustomRole) {
            $tags += ($Lab.Machines.PostInstallationActivity | Where-Object IsCustomRole).RoleName
            foreach ( $role in (($Lab.Machines.PostInstallationActivity | Where-Object IsCustomRole).RoleName)) {
                $config_paths += Join-Path -Path $global:LabSources\CustomRoles -ChildPath $role
            }
        }
        if ($Lab.Machines.PreInstallationActivity | Where-Object IsCustomRole) {
            $tags += ($Lab.Machines.PreInstallationActivity | Where-Object IsCustomRole).RoleName
            foreach ( $role in (($Lab.Machines.PreInstallationActivity | Where-Object IsCustomRole).RoleName)) {
                $config_paths += Join-Path -Path $global:LabSources\CustomRoles -ChildPath $role
            }
        }
        $configuration.Run.Path = $config_paths | Sort-Object -Unique
        $configuration.Filter.Tag = $tags
        $configuration.Should.ErrorAction = 'Continue'
        $configuration.TestResult.Enabled = $true
        
        if ($OutputFile) {
            $configuration.TestResult.OutputPath = $OutputFile
        }
        $configuration.Output.Verbosity = $Show

        Invoke-Pester -Configuration $configuration
        Remove-Variable -Name pesterLab -Scope Global
    }
}
