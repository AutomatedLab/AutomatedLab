function Get-LabTfsFeed
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ComputerName,

        [string]
        $FeedName
    )
    
    $lab = Get-Lab
    $tfsVm = Get-LabVM -ComputerName $ComputerName
    $defaultParam = Get-LabTfsParameter -ComputerName $ComputerName
    
    $defaultParam['FeedName']   = $FeedName
    $defaultParam['ApiVersion'] = '5.0-preview.1'
    
    $feed = Get-TfsFeed @defaultParam
        
    if (-not $tfsVm.SkipDeployment -and $(Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        if ($feed.url -match 'http(s?)://(?<Host>[\w\.]+):(?<Port>\d+)/')
        {
            $feed.url = $feed.url.Replace($Matches.Host, $tfsVm.AzureConnectionInfo.DnsName)
            $feed.url = $feed.url.Replace($Matches.Port, $defaultParam.Port)
        }
    }

    if ($feed.url -match '(?<url>http.*)\/_apis')
    {
        $nugetV2Url = '{0}/_packaging/{1}/nuget/v2' -f $Matches.url, $feed.name
        $feed | Add-Member -Name NugetV2Url -MemberType NoteProperty $nugetV2Url
        
        $feed | Add-Member -Name NugetCredential -MemberType NoteProperty ($tfsVm.GetCredential($lab))
        
        $nugetApiKey = '{0}@{1}:{2}' -f $feed.NugetCredential.GetNetworkCredential().UserName, $feed.NugetCredential.GetNetworkCredential().Domain, $feed.NugetCredential.GetNetworkCredential().Password
        $feed | Add-Member -Name NugetApiKey -MemberType NoteProperty -Value $nugetApiKey
    }
    
    $feed
}
