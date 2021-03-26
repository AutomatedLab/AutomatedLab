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
        $Tag
    )

    process
    {
        foreach ($snippetName in $Name)
        {
            $scriptblockName = 'AutomatedLab.{0}.{1}' -f $Type, $snippetName

            Get-PSFScriptblock -Name $scriptblockName -Description $Description -Tag $Tag
        }
    }
}
