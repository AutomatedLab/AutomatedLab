function Get-LabRecipe
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string[]]
        $Name
    )

    $recipePath = Join-Path -Path $HOME -ChildPath 'automatedLab\recipes'

    $recipes = Get-ChildItem -Path $recipePath

    if ($Name)
    {
        $recipes = $recipes | Where-Object -Property BaseName -in $Name
    }

    foreach ($recipe in $recipes)
    {
        $recipe | Get-Content -Raw | ConvertFrom-Json
    }
}
