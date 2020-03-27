function Get-LabRecipe
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string[]]
        $Name,

        [Parameter()]
        [scriptblock]
        $RecipeContent
    )

    if ($RecipeContent)
    {
        if ($Name.Count -gt 1)
        {
            Write-PSFMessage -Level Warning -Message "Provided more than one name when using RecipeContent. Ignoring every value but the first."
        }

        $newScript = "[hashtable]@{$($RecipeContent.ToString())}"
        $newScriptBlock = [scriptblock]::Create($newScript)
        $table = & $newScriptBlock
        $mandatoryKeys = @(
            'Name'
            'DeployRole'
        )
        $allowedKeys = @(
            'Name'
            'Description'
            'RequiredProductIsos'
            'DeployRole'
            'DefaultVirtualizationEngine'
            'DefaultDomainName'
            'DefaultAddressSpace'
            'DefaultOperatingSystem'
            'VmPrefix'
        )

        $table.Name = $Name[0]
        $allowedKeys.ForEach({if (-not $table.ContainsKey($_)){$table.Add($_, $null)}})
        [bool] $shouldAlsoDeploySql = ($table.DeployRole -match 'CI_CD|DSCPull').Count -gt 0
        [bool] $shouldAlsoDeployDomain = ($table.DeployRole -match 'Exchange|PKI|DSCPull').Count -gt 0
        [bool] $shouldAlsoDeployPki = ($table.DeployRole -match 'CI_CD|DSCPull').Count -gt 0

        [string[]]$roles = $table.DeployRole.Clone()
        if ($shouldAlsoDeploySql -and $table.DeployRole -notcontains 'SQL') {$roles += 'SQL'}
        if ($shouldAlsoDeployDomain -and $table.DeployRole -notcontains 'Domain') {$roles += 'Domain'}
        if ($shouldAlsoDeployPki -and $table.DeployRole -notcontains 'PKI') {$roles += 'PKI'}
        $table.DeployRole = $roles

        $test = Test-HashtableKeys -Hashtable $table -ValidKeys $allowedKeys -MandatoryKeys $mandatoryKeys -Quiet

        if (-not $test) {}

        return ([pscustomobject]$table)
    }

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
