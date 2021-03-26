function New-LabSnippet
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,

        [Parameter(Mandatory)]
        [ValidateSet('Sample', 'Snippet', 'CustomRole')]
        [string]
        $Type,

        [string[]]
        $Tag,

        [Parameter(Mandatory)]
        [scriptblock]
        $ScriptBlock,

        [string[]]
        $DependsOn,

        [switch]
        $Force,

        [switch]
        $NoExport
    )

    $existingSnippet = Get-LabSnippet -Name $Name

    if ($existingSnippet -and -not $Force)
    {
        Write-PSFMessage -Level Error -Message "$Type $Name already exists. Use -Force to overwrite."
        return
    }

    foreach ($dependency in $DependsOn)
    {
        if (Get-LabSnippet -Name $dependency) { continue }
        Write-PSFMessage -Level Warning -Message "Snippet dependency $dependency has not been registered."
    }

    $scriptblockName = 'AutomatedLab.{0}.{1}' -f $Type, $Name
    Set-PSFScriptblock -ScriptBlock $ScriptBlock -Name $scriptblockName -Tag $Tag -Description $Description

    if ($NoExport) { return }

    $location = Get-PSFConfigValue -FullName AutomatedLab.Recipe.SnippetStore
    $filePath = Join-Path -Path $location -ChildPath "$scriptblockName.ps1"
    $metaPath = Join-Path -Path $location -ChildPath "$scriptblockName.psd1"
    if (-not (Test-Path -Path $location))
    {
        $null = New-Item -Path $location -ItemType Directory -Force
    }

    Set-Content -Path $filePath -Value $ScriptBlock.ToString() -Encoding Unicode -Force

    @"
@{
    Name = '$Name'
    Type = '$Type'
    Tag  = @(
        $(($Tag | ForEach-Object {"'$_'"}) -join ",")
    )
    DependsOn  = @(
        $(($DependsOn | ForEach-Object {"'$_'"}) -join ",")
    )
    Description = '$($Description.Replace("'", "''"))'
}
"@ | Set-Content -Path $metaPath -Force
}
