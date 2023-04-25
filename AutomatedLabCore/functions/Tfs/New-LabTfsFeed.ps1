function New-LabTfsFeed
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        
        [Parameter(Mandatory)]
        [string]
        $FeedName,
        
        [object[]]
        $FeedPermissions,
        
        [switch]
        $PassThru
    )
    
    $tfsVm = Get-LabVM -ComputerName $computerName
    $role = $tfsVm.Roles | Where-Object Name -match 'Tfs\d{4}|AzDevOps'
    $defaultParam = Get-LabTfsParameter -ComputerName $ComputerName
    $defaultParam['FeedName']   = $FeedName
    $defaultParam['ApiVersion'] = '5.0-preview.1'
    
    try
    {
        New-TfsFeed @defaultParam -ErrorAction Stop
        
        if ($FeedPermissions)
        {
            Set-TfsFeedPermission @defaultParam -Permissions $FeedPermissions
        }
    }
    catch
    {
        Write-Error $_
    }
    
    if ($PassThru)
    {
        Get-LabTfsFeed -ComputerName $ComputerName -FeedName $FeedName
    }
}
