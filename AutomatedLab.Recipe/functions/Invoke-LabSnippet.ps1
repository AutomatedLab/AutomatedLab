function Invoke-LabSnippet
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $Name,

        [hashtable]
        $LabParameter = @{}
    )

    begin
    {
        $scriptBlockOrder = @{}
        try { [AutomatedLab.LabTelemetry]::Instance.FunctionCalled($PSCmdlet.MyInvocation.InvocationName) } catch {}
    }

    process
    {
        foreach ($snip in $Name)
        {
            $snip = $snip -replace 'AutomatedLab\..*\.'
            $schnippet = Get-LabSnippet -Name $snip
            [string[]]$dependencies = ($schnippet.Tag | Where-Object { $_.StartsWith('DependsOn_') }) -replace 'DependsOn_'
            $scriptBlockOrder[($schnippet.Name -replace 'AutomatedLab\..*\.')] = $dependencies
        }
    }

    end
    {
        try
        {
            $order = Get-TopologicalSort -EdgeList $scriptBlockOrder -ErrorAction Stop
            Write-PSFMessage -Message "Calculated dependency graph: $($order -join ',')"
        }
        catch
        {
            Write-Error -ErrorRecord $_
            return
        }

        $snippets = Get-LabSnippet -Name $order
        if ($snippets.Count -ne $order.Count)
        {
            Write-PSFMessage -Level Error -Message "Missing dependencies in graph: $($order -join ',')"
        }

        foreach ($blockName in $order)
        {
            $schnippet = Get-LabSnippet -Name $blockName
            $block = $schnippet.ScriptBlock
            $clonedParam = $LabParameter.Clone()
            $commonParameters = [System.Management.Automation.Internal.CommonParameters].GetProperties().Name
            $commandParameterKeys = $schnippet.Parameters
            $parameterKeys = $clonedParam.Keys.GetEnumerator() | ForEach-Object { $_ }
            
            [string[]]$keysToRemove = if ($parameterKeys -and $commandParameterKeys)
            {
                Compare-Object -ReferenceObject $commandParameterKeys -DifferenceObject $parameterKeys |
                Select-Object -ExpandProperty InputObject
            }
            else
            {
                @()
            }

            $keysToRemove = $keysToRemove + $commonParameters | Select-Object -Unique #remove the common parameters
            
            foreach ($key in $keysToRemove)
            {
                $clonedParam.Remove($key)
            }

            . $block @clonedParam
        }
    }
}