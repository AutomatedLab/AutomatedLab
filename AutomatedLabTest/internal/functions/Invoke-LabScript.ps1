function Invoke-LabScript
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [hashtable]$Replace
    )

    $result = New-Object PSObject -Property ([ordered]@{
            ScriptName = Split-Path -Path $Path -Leaf
            Completed = $false
            ErrorCount = 0
            Errors = $null
            ScriptFullName = $Path
            Output = $null
            RemoveErrors = $null
    })
    $result.PSObject.TypeNames.Insert(0, 'AutomatedLab.TestResult')

    Write-PSFMessage -Level Host "Invoking script '$Path'"
    Write-PSFMessage -Level Host '-------------------------------------------------------------'
    try
    {
        Clear-Host
        $content = Get-Content -Path $Path -Raw

        foreach ($element in $Replace.GetEnumerator())
        {
            $content = $content -replace $element.Key, $element.Value
        }

        $content = [scriptblock]::Create($content)

        Invoke-Command -ScriptBlock $content -ErrorVariable invokeError
        $result.Errors = $invokeError
        $result.Completed = $true
    }
    catch
    {
        Write-Error -Exception $_.Exception -Message "Error invoking the script '$Path': $($_.Exception.Message)"
        $result.Errors = $_
        $result.Completed = $false
    }
    finally
    {
        Start-Sleep -Seconds 1
        $result.Output = Get-ConsoleText
        $result.ErrorCount = $result.Errors.Count
        Clear-Host

        if (Get-Lab -ErrorAction SilentlyContinue)
        {
            Remove-Lab -Confirm:$false -ErrorVariable removeErrors
        }

        $result.RemoveErrors = $removeErrors

        Write-PSFMessage -Level Host '-------------------------------------------------------------'
        Write-PSFMessage -Level Host "Finished invkoing script '$Path'"

        $result
    }
}
