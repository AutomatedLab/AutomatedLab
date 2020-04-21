function Test-SimpleNullComparsion
{

    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param (

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    $binExpressionAsts = $ScriptBlockAst.FindAll( { $args[0] -is [System.Management.Automation.Language.BinaryExpressionAst] }, $false);

    foreach ($binExpressionAst in $binExpressionAsts)
    {
        # If operator is eq, ceq,ieq: $null -eq $bla or $bla -eq $Null: Use simple comparison
        # Suggested correction: -not $bla
        # If operator ne,cne,ine: $null -ne $bla, $bla -ne $null
        # Suggested correction $bla
        if ($binExpressionAst.Operator -in 'Equals', 'Ieq', 'Ceq' -and ($binExpressionAst.Left.Extent.Text -eq '$null' -or $binExpressionAst.Right.Extent.Text -eq '$null'))
        {
            $theCorrectExtent = if ($binExpressionAst.Right.Extent.Text -eq '$null')
            {
                $binExpressionAst.Left.Extent.Text
            }
            else
            {
                $binExpressionAst.Right.Extent.Text
            }

            [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{

                Message              = 'Try to use simple $null comparisons'
                Extent               = $binExpressionAst.Extent
                RuleName             = 'ALSimpleNullComparison'
                Severity             = 'Warning'
                SuggestedCorrections = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent[]](
                    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
                        $binExpressionAst.Extent.StartLineNumber,
                        $binExpressionAst.Extent.EndLineNumber,
                        $binExpressionAst.Extent.StartColumnNumber,
                        $binExpressionAst.Extent.EndColumnNumber,
                        "-not $theCorrectExtent",
                        $binExpressionAst.Extent.File,
                        'Try to use simple $null comparisons'
                    )
                )
            }
        }

        if ($binExpressionAst.Operator -in 'Ne', 'Cne', 'Ine' -and ($binExpressionAst.Left.Extent.Text -eq '$null' -or $binExpressionAst.Right.Extent.Text -eq '$null'))
        {
            $theCorrectExtent = if ($binExpressionAst.Right.Extent.Text -eq '$null')
            {
                $binExpressionAst.Left.Extent.Text
            }
            else
            {
                $binExpressionAst.Right.Extent.Text
            }

            [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{

                Message              = 'Try to use simple $null comparisons'
                Extent               = $binExpressionAst.Extent
                RuleName             = 'ALSimpleNullComparison'
                Severity             = 'Warning'
                SuggestedCorrections = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent[]](
                    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
                        $binExpressionAst.Extent.StartLineNumber,
                        $binExpressionAst.Extent.EndLineNumber,
                        $binExpressionAst.Extent.StartColumnNumber,
                        $binExpressionAst.Extent.EndColumnNumber,
                        $theCorrectExtent,
                        $binExpressionAst.Extent.File,
                        'Try to use simple $null comparisons'
                    )
                )
            }
        }
    }
}