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

        [Pester.OutputTypes]
        $Show = 'None',

        [switch]
        $PassThru,

        [string]
        $OutputFile,

        [ValidateSet('NUnitXml')]
        [string]
        $OutputFormat = 'NUnitXml'
    )

    process
    {
        if (-not $Lab)
        {
            $Lab = Import-Lab -Name $LabName -ErrorAction Stop -NoDisplay -NoValidation -PassThru
        }

        # Execute all role-specific tests
        $null = $PSBoundParameters.Remove('Lab')
        $null = $PSBoundParameters.Remove('LabName')

        Invoke-Pester -Script @{
            Path       = Join-Path -Path $PSCmdlet.MyInvocation.MyCommand.Module.ModuleBase -ChildPath 'internal/tests'
            Parameters = @{
                Lab = $Lab
            }
        } -Tag $Lab.Machines.Roles.Name @PSBoundParameters
    }
}
