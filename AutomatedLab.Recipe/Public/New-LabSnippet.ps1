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
    try { [AutomatedLab.LabTelemetry]::Instance.FunctionCalled($PSCmdlet.MyInvocation.InvocationName) } catch {}

    if ($existingSnippet -and -not $Force)
    {
        Write-PSFMessage -Level Error -Message "$Type $Name already exists. Use -Force to overwrite."
        return
    }

    foreach ($dependency in $DependsOn)
    {
        if ($Tag -notcontains "DependsOn_$($dependency)")
        {
            $Tag += "DependsOn_$($dependency)"
        }

        if (Get-LabSnippet -Name $dependency) { continue }
        Write-PSFMessage -Level Warning -Message "Snippet dependency $dependency has not been registered."
    }

    $scriptblockName = 'AutomatedLab.{0}.{1}' -f $Type, $Name
    Set-PSFScriptblock -ScriptBlock $ScriptBlock -Name $scriptblockName -Tag $Tag -Description $Description -Global

    if ($NoExport) { return }

    Export-LabSnippet -Name $Name -DependsOn $DependsOn
}
