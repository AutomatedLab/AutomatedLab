function Get-LabIssuingCA
{

    [OutputType([AutomatedLab.Machine])]
    [cmdletBinding()]

    param(
        [string]$DomainName
    )

    $lab = Get-Lab

    if ($DomainName)
    {
        if ($DomainName -notin $lab.Domains.Name)
        {
            Write-Error "The domain '$DomainName' is not defined in the lab."
            return
        }

        $machines = (Get-LabVM -Role CaRoot, CaSubordinate) | Where-Object DomainName -eq $DomainName
    }
    else
    {
        $machines = (Get-LabVM -Role CaRoot, CaSubordinate)
    }

    if (-not $machines)
    {
        Write-Warning 'There is no Certificate Authority deployed in the lab. Cannot get an Issuing Certificate Authority.'
        return
    }

    $issuingCAs = Invoke-LabCommand -ComputerName $machines -ScriptBlock {
        Start-Service -Name CertSvc -ErrorAction SilentlyContinue
        $templates = certutil.exe -CATemplates
        if ($templates -like '*Machine*')
        {
            $env:COMPUTERNAME
        }
    } -PassThru -NoDisplay

    if (-not $issuingCAs)
    {
        Write-Error 'There was no issuing CA found'
        return
    }

    Get-LabVM -ComputerName $issuingCAs | ForEach-Object {
        $caName = Invoke-LabCommand -ComputerName $_ -ScriptBlock { ((certutil -config $args[0] -ping)[1] -split '"')[1] } -ArgumentList $_.Name -PassThru -NoDisplay

        $_ | Add-Member -Name CaName -MemberType NoteProperty -Value $caName -Force
        $_ | Add-Member -Name CaPath -MemberType ScriptProperty -Value { $this.FQDN + '\' + $this.CaName } -Force
        $_
    }
}
