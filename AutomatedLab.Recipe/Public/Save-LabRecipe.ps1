function Save-LabRecipe
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [pscustomobject]
        $Recipe
    )

    $recipeFileName = Join-Path -Path $HOME -ChildPath "automatedLab\recipes\$($Recipe.Name).json"

    if ($PSCmdlet.ShouldProcess($recipeFileName, 'Storing recipe'))
    {
        $Recipe | ConvertTo-Json | Set-Content -Path $recipeFileName -NoNewline -Force
    }
}
