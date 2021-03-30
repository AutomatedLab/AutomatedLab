function Remove-LabSnippet
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Name
    )

    process
    {
        $schnippet = Get-LabSnippet -Name $Name
        if (-not $schnippet)
        {
            Write-PSFMessage -Level Warning -Message "Snippet $Name not found"
            break
        }

        $location = Get-PSFConfigValue -FullName AutomatedLab.Recipe.SnippetStore
        $filePath = Join-Path -Path $location -ChildPath "$($schnippet.Name).ps1"
        $metaPath = Join-Path -Path $location -ChildPath "$($schnippet.Name).psd1"

        Remove-Item -Path $filePath, $metaPath -ErrorAction SilentlyContinue
    }
}