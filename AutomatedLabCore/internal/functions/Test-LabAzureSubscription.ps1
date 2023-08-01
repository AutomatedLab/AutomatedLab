function Test-LabAzureSubscription
{
    [CmdletBinding()]
    param ( )

    Test-LabHostConnected -Throw -Quiet

    try
    {
        $ctx = Get-AzContext
    }
    catch
    {
        throw "No Azure Context found, Please run 'Connect-AzAccount' first"
    }
}
