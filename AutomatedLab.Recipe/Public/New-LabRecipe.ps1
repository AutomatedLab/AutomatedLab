function New-LabRecipe
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        # Name of the lab and recipe
        [Parameter(Mandatory)]
        [string]
        $Name,

        # Description of lab
        [Parameter()]
        [string]
        $Description,

        [Parameter()]
        [string]
        $VmPrefix,

        # Roles this recipe deploys
        [Parameter(Mandatory)]
        [ValidateSet(
            'Domain',
            'PKI',
            'SQL',
            'Exchange',
            'CI_CD',
            'DSCPull'
        )]
        [string[]]
        $DeployRole,

        [Parameter()]
        [ValidateSet('HyperV', 'Azure', 'VMWare')]
        [string]
        $DefaultVirtualizationEngine,

        [Parameter()]
        [string]
        $DefaultDomainName,

        [Parameter()]
        [AutomatedLab.IPNetwork]
        $DefaultAddressSpace,

        [Parameter()]
        [AutomatedLab.OperatingSystem]
        $DefaultOperatingSystem,

        [switch]
        $Force,

        [switch]
        $PassThru
    )

    $labContent = @{
        Name                        = $Name
        Description                 = $Description
        RequiredProductIsos         = @()
        DeployRole                  = $DeployRole
        DefaultVirtualizationEngine = if ($DefaultVirtualizationEngine) {$DefaultVirtualizationEngine} else {'HyperV'}
        DefaultDomainName           = if ($DefaultDomainName) {$DefaultDomainName} else {'contoso.com'}
        DefaultAddressSpace         = if ($DefaultAddressSpace) {$DefaultAddressSpace.ToString()} else {'192.168.99.99/24'}
        DefaultOperatingSystem      = if ($DefaultOperatingSystem) {$DefaultOperatingSystem.OperatingSystemName} else {'Windows Server 2016 Datacenter'}
        VmPrefix                    = if ($VmPrefix) {$VmPrefix} else {(1..4 | ForEach-Object { [char[]](65..90) | Get-Random }) -join ''}
    }

    [bool] $shouldAlsoDeploySql = ($DeployRole -match 'CI_CD|DSCPull').Count -gt 0
    [bool] $shouldAlsoDeployDomain = ($DeployRole -match 'Exchange|PKI|DSCPull').Count -gt 0
    [bool] $shouldAlsoDeployPki = ($DeployRole -match 'CI_CD|DSCPull').Count -gt 0

    $roles = $DeployRole.Clone()
    if ($shouldAlsoDeploySql -and $DeployRole -notcontains 'SQL') {$roles += 'SQL'}
    if ($shouldAlsoDeployDomain -and $DeployRole -notcontains 'Domain') {$roles += 'Domain'}
    if ($shouldAlsoDeployPki -and $DeployRole -notcontains 'PKI') {$roles += 'PKI'}
    $labContent.DeployRole = $roles

    foreach ($role in $roles)
    {
        if ($role -notin 'Domain', 'PKI', 'DscPull')
        {
            $labContent.RequiredProductIsos += $role
        }
    }

    if (-not (Test-Path -Path (Join-Path -Path $HOME -ChildPath 'automatedlab\recipes')))
    {
        $null = New-Item -ItemType Directory -Path (Join-Path -Path $HOME -ChildPath 'automatedlab\recipes')
    }
    $recipeFileName = Join-Path -Path $HOME -ChildPath "automatedLab\recipes\$Name.json"

    if ((Test-Path -Path $recipeFileName) -and -not $Force.IsPresent)
    {
        Write-PSFMessage -Level Warning -Message "$recipeFileName exists and -Force was not used. Not storing recipe."
        return
    }

    if ($PSCmdlet.ShouldProcess($recipeFileName, 'Storing recipe'))
    {
        $labContent | ConvertTo-Json | Set-Content -Path $recipeFileName -NoNewline -Force
    }

    if ($PassThru) {$labContent}
}
