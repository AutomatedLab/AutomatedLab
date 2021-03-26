function Set-LabSnippet
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Name,

        [ValidateSet('Sample','Snippet', 'CustomRole')]
        [string]
        $Type,

        [string[]]
        $Tag,

        [scriptblock]
        $ScriptBlock
    )

    process
    {

    }
}