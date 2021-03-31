function Get-LabSnippet
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $Name = '*',

        [string]
        $Description,

        [ValidateSet('Sample', 'Snippet', 'CustomRole')]
        [string]
        $Type = '*',

        [string[]]
        $Tag,

        [switch]
        $Syntax
    )

    process
    {
        foreach ($snippetName in $Name)
        {
            $scriptblockName = 'AutomatedLab.{0}.{1}' -f $Type, $snippetName

            $block = Get-PSFScriptblock -Name $scriptblockName -Description $Description -Tag $Tag
            $parameters = $block.ScriptBlock.Ast.ParamBlock.Parameters.Name.VariablePath.UserPath
            if ($parameters)
            {
                $block | Add-Member -NotePropertyName Parameters -NotePropertyValue $parameters -Force
            }

            if ($Syntax -and $block)
            {
                foreach ($blk in $block)
                {
                    $flatName = $blk.Name -replace '^AutomatedLab\..*\.'
                    "Invoke-LabSnippet -Name $($flatName) -LabParameter @{`r`n`0`0`0`0$($blk.Parameters -join `"='value'`r`n`0`0`0`0")='value'`r`n}`r`n"
                }
                continue
            }

            $block
        }
    }
}
