function Set-LabSnippet
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Name,

        [string[]]
        $DependsOn,

        [ValidateSet('Sample','Snippet', 'CustomRole')]
        [string]
        $Type,

        [string[]]
        $Tag,

        [scriptblock]
        $ScriptBlock,

        [switch]
        $NoExport
    )

    process
    {
        $schnippet = Get-LabSnippet -Name $Name
        if (-not $schnippet)
        {
            Write-PSFMessage -Level Warning -Message "Snippet $Name not found"
            break
        }

        if (-not $Tag)
        {
            $Tag = $schnippet.Tag
        }

        foreach ($dependency in $DependsOn)
        {
            if ($Tag -contains "DependsOn_$($dependency)") { Continue }

            $Tag += "DependsOn_$($dependency)"
        }

        if (-not $Description)
        {
            $Description = $schnippet.Description
        }

        if (-not $ScriptBlock)
        {
            $ScriptBlock = $schnippet.ScriptBlock
        }

        Set-PSFScriptblock -Name $Name -Description $Description -Tag $Tag -Scriptblock $ScriptBlock -Global
        
        if ($NoExport) { return }

        Export-LabSnippet -Name $Name -DependsOn $DependsOn
    }
}