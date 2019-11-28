function Remove-LabRecipe
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'ByName')]
        [string]
        $Name,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ByRecipe')]
        [System.Management.Automation.PSCustomObject]
        $Recipe
    )

    begin
    {
        $recipePath = Join-Path -Path $HOME -ChildPath 'automatedLab\recipes'
    }

    process
    {
        if (-not $Name)
        {
            $Name = $Recipe.Name
        }

        Get-ChildItem -File -Filter *.json -Path $recipePath | Where-Object -Property BaseName -eq $Name | Remove-Item
    }
}
