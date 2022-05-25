function Invoke-LabPester
{
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

    process
    {
        if (-not $Lab)
        {
            $Lab = Import-Lab -Name $LabName -ErrorAction Stop -NoDisplay -NoValidation -PassThru
        }

        $global:pesterLab = $Lab # No parameters in Pester v5 yet
        $configuration = [PesterConfiguration]::Default
        $configuration.Run.Path = Join-Path -Path $PSCmdlet.MyInvocation.MyCommand.Module.ModuleBase -ChildPath 'internal/tests'
        $configuration.Run.PassThru = $PassThru.IsPresent
        [string[]]$tags = 'General'
        
        if ($Lab.Machines.Roles.Name)
        {
            $tags += $Lab.Machines.Roles.Name
        }
        if ($Lab.Machines.PostInstallationActivity | Where-Object IsCustomRole)
        {
            $tags += ($Lab.Machines.PostInstallationActivity | Where-Object IsCustomRole).RoleName
        }
        if ($Lab.Machines.PreInstallationActivity | Where-Object IsCustomRole)
        {
            $tags += ($Lab.Machines.PreInstallationActivity | Where-Object IsCustomRole).RoleName
        }

        $configuration.Filter.Tag = $tags
        $configuration.Should.ErrorAction = 'Continue'
        $configuration.TestResult.Enabled = $true
        if ($OutputFile)
        {
            $configuration.TestResult.OutputPath = $OutputFile
        }
        $configuration.Output.Verbosity = $Show

        Invoke-Pester -Configuration $configuration
        Remove-Variable -Name pesterLab -Scope Global
    }
}
