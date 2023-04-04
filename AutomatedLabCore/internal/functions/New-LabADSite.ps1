function New-LabADSite
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [string]$SiteName,

        [Parameter(Mandatory)]
        [string]$SiteSubnet
    )

    Write-LogFunctionEntry

    $lab = Get-Lab
    $machine = Get-LabVM -ComputerName $ComputerName
    $dcRole = $machine.Roles | Where-Object Name -like '*DC'

    if (-not $dcRole)
    {
        Write-PSFMessage "No Domain Controller roles found on computer '$Computer'"
        return
    }

    Write-PSFMessage -Message "Try to find domain root machine for '$ComputerName'"
    $rootDc = Get-LabVM -Role RootDC | Where-Object DomainName -eq $machine.DomainName
    if (-not $rootDc)
    {
        Write-PSFMessage -Message "No RootDC found in same domain as '$ComputerName'. Looking for FirstChildDC instead"

        $domain = $lab.Domains | Where-Object Name -eq $machine.DomainName
        if (-not $lab.IsRootDomain($domain))
        {
            $parentDomain = $lab.GetParentDomain($domain)
            $rootDc = Get-LabVM -Role RootDC | Where-Object DomainName -eq $parentDomain
        }
    }

    $createSiteCmd = {
        param
        (
            $ComputerName, $SiteName, $SiteSubnet
        )

        $PSDefaultParameterValues = @{
            '*-AD*:Server' = $env:COMPUTERNAME
        }

        Write-Verbose -Message "For computer '$ComputerName', create AD site '$SiteName' in subnet '$SiteSubnet'"

        if (-not (Get-ADReplicationSite -Filter "Name -eq '$SiteName'"))
        {
            Write-Verbose -Message "SiteName '$SiteName' does not exist. Attempting to create it now"
            New-ADReplicationSite -Name $SiteName
        }
        else
        {
            Write-Verbose -Message "SiteName '$SiteName' already exists"
        }

        $SiteSubnet = $SiteSubnet -split ',|;'
        foreach ($sn in $SiteSubnet)
        {
            $sn = $sn.Trim()
            if (-not (Get-ADReplicationSubNet -Filter "Name -eq '$sn'"))
            {
                Write-Verbose -Message "SiteSubnet does not exist. Attempting to create it now and associate it with site '$SiteName'"
                New-ADReplicationSubnet -Name $sn -Site $SiteName -Location $SiteName
            }
            else
            {
                Write-Verbose -Message "SiteSubnet '$sn' already exists"
            }
        }

        $sites = (Get-ADReplicationSite -Filter 'Name -ne "Default-First-Site-Name"').Name
        foreach ($site in $sites)
        {
            $otherSites = $sites | Where-Object { $_ -ne $site }
            foreach ($otherSite in $otherSites)
            {
                if (-not (Get-ADReplicationSiteLink -Filter "(name -eq '[$site]-[$otherSite]')") -and -not
                (Get-ADReplicationSiteLink -Filter "(name -eq '[$otherSite]-[$Site]')"))
                {
                    Write-Verbose -Message "Site link '[$site]-[$otherSite]' does not exist. Creating it now"
                    New-ADReplicationSiteLink -Name "[$site]-[$otherSite]" `
                    -SitesIncluded $site, $otherSite `
                    -Cost 100 `
                    -ReplicationFrequencyInMinutes 15 `
                    -InterSiteTransportProtocol IP `
                    -OtherAttributes @{ 'options' = 5 }
                }
            }
        }
    }

    try
    {
        $null = Invoke-LabCommand -ComputerName $rootDc -NoDisplay -PassThru -ScriptBlock $createSiteCmd `
        -ArgumentList $ComputerName, $SiteName, $SiteSubnet -ErrorAction Stop
    }
    catch {
        Restart-LabVM -ComputerName $ComputerName -Wait
        Wait-LabADReady -ComputerName $ComputerName
        
        Invoke-LabCommand -ComputerName $rootDc -NoDisplay -PassThru -ScriptBlock $createSiteCmd `
        -ArgumentList $ComputerName, $SiteName, $SiteSubnet -ErrorAction Stop
    }

    Write-LogFunctionExit
}
