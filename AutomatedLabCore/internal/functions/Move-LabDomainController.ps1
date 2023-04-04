function Move-LabDomainController
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [string]$SiteName
    )

    Write-LogFunctionEntry


    $dcRole = (Get-LabVM -ComputerName $ComputerName).Roles | Where-Object Name -like '*DC'

    if (-not $dcRole)
    {
        Write-PSFMessage "No Domain Controller roles found on computer '$ComputerName'"
        return
    }

    $machine = Get-LabVM -ComputerName $ComputerName
    $lab = Get-Lab

    $forest = if ($lab.IsRootDomain($machine.DomainName))
    {
        $machine.DomainName
    }
    else
    {
        $lab.GetParentDomain($machine.DomainName)
    }

    Write-PSFMessage -Message "Try to find domain root machine for '$ComputerName'"
    $domainRootMachine = Get-LabVM -Role RootDC | Where-Object DomainName -eq $forest
    if (-not $domainRootMachine)
    {
        Write-PSFMessage -Message "No RootDC found in same domain as '$ComputerName'. Looking for FirstChildDC instead"

        $domainRootMachine = Get-LabVM -Role FirstChildDC | Where-Object DomainName -eq $machine.DomainName
    }
    
    $null = Invoke-LabCommand -ComputerName $domainRootMachine -NoDisplay -PassThru -ScriptBlock `
    {
        param
        (
            $ComputerName, $SiteName
        )

        $searchBase = (Get-ADRootDSE).ConfigurationNamingContext

        Write-Verbose -Message "Moving computer '$ComputerName' to AD site '$SiteName'"
        $targetSite = Get-ADObject -Filter 'ObjectClass -eq "site" -and CN -eq $SiteName' -SearchBase $searchBase
        Write-Verbose -Message "Target site: '$targetSite'"
        $dc =  Get-ADObject -Filter "ObjectClass -eq 'server' -and Name -eq '$ComputerName'" -SearchBase $searchBase
        Write-Verbose -Message "DC distinguished name: '$dc'"
        Move-ADObject -Identity $dc -TargetPath "CN=Servers,$($TargetSite.DistinguishedName)"

    } -ArgumentList $ComputerName, $SiteName

    Write-LogFunctionExit
}
