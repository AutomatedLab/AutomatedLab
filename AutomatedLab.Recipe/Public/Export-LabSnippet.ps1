function Export-LabSnippet
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Name,

        [string[]]
        $DependsOn,

        [switch]
        $MetaData
    )

    process
    {
        $schnippet = Get-LabSnippet -Name $Name
        $location = Get-PSFConfigValue -FullName AutomatedLab.Recipe.SnippetStore
        $filePath = Join-Path -Path $location -ChildPath "$($schnippet.Name).ps1"
        $metaPath = Join-Path -Path $location -ChildPath "$($schnippet.Name).psd1"
        if (-not (Test-Path -Path $location))
        {
            $null = New-Item -Path $location -ItemType Directory -Force
        }

        if (-not $MetaData.IsPresent)
        {
            Set-Content -Path $filePath -Value $schnippet.ScriptBlock.ToString() -Encoding Unicode -Force
        }

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
}