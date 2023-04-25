function Get-LabTfsParameter
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ComputerName,

        [switch]
        $Local
    )
    
    $lab = Get-Lab
    $tfsVm = Get-LabVM -ComputerName $ComputerName
    $role = $tfsVm.Roles | Where-Object -Property Name -match 'Tfs\d{4}|AzDevOps'
    $bwRole = $tfsVm.Roles | Where-Object -Property Name -eq TfsBuildWorker
    $initialCollection = 'AutomatedLab'
    $tfsPort = 8080
    $tfsInstance = if (-not $bwRole) {$tfsVm.FQDN} else {$bwRole.Properties.TfsServer}

    if ($role -and $role.Properties.ContainsKey('Port'))
    {
        $tfsPort = $role.Properties['Port']
    }
    if ($bwRole -and $bwRole.Properties.ContainsKey('Port'))
    {
        $tfsPort = $bwRole.Properties['Port']
    }

    if (-not $Local.IsPresent -and (Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and -not ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment))
    {
        $tfsPort = if ($bwRole) {
            (Get-LWAzureLoadBalancedPort -DestinationPort $tfsPort -ComputerName $bwRole.Properties.TfsServer -ErrorAction SilentlyContinue).FrontendPort
        }
        else
        {
            (Get-LWAzureLoadBalancedPort -DestinationPort $tfsPort -ComputerName $tfsVm -ErrorAction SilentlyContinue).FrontendPort
        }

        if (-not $tfsPort)
        {
            Write-Error -Message 'There has been an error setting the Azure port during TFS installation. Cannot continue rolling out release pipeline'
            return
        }

        $tfsInstance = if ($bwRole) {
            (Get-LabVm $bwRole.Properties.TfsServer).AzureConnectionInfo.DnsName
        }
        else
        {
            $tfsVm.AzureConnectionInfo.DnsName
        }
    }

    if ($role -and $role.Properties.ContainsKey('InitialCollection'))
    {
        $initialCollection = $role.Properties['InitialCollection']
    }

    if ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment)
    {
        $tfsInstance = 'dev.azure.com'
        $initialCollection = $role.Properties['Organisation']
        $accessToken = $role.Properties['PAT']
        $tfsPort = 443
    }

    if ($bwRole -and $bwRole.Properties.ContainsKey('Organisation'))
    {
        $tfsInstance = 'dev.azure.com'
        $initialCollection = $bwRole.Properties['Organisation']
        $accessToken = $bwRole.Properties['PAT']
        $tfsPort = 443
    }

    if (-not $role)
    {
        $tfsVm = Get-LabVm -ComputerName $bwrole.Properties.TfsServer
        $role = $tfsVm.Roles | Where-Object -Property Name -match 'Tfs\d{4}|AzDevOps'
    }
    $credential = $tfsVm.GetCredential((Get-Lab))
    $useSsl = $tfsVm.InternalNotes.ContainsKey('CertificateThumbprint') -or ($role.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment) -or ($bwRole -and $bwRole.Properties.ContainsKey('Organisation'))
    
    $defaultParam = @{
        InstanceName         = $tfsInstance
        Port                 = $tfsPort
        CollectionName       = $initialCollection
        UseSsl               = $useSsl
        SkipCertificateCheck = $true
    }

    $defaultParam.ApiVersion = switch ($role.Name)
    {
        'Tfs2015' { '2.0'; break }
        'Tfs2017' { '3.0'; break }
        { $_ -match '2018|AzDevOps' } { '4.0'; break }
        default { '2.0' }
    }

    if (($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment) -or ($bwRole -and $bwRole.Properties.ContainsKey('Organisation')))
    {
        $defaultParam.ApiVersion = '5.1'
    }

    if ($accessToken)
    {
        $defaultParam.PersonalAccessToken = $accessToken
    }
    elseif ($credential)
    {
        $defaultParam.Credential = $credential
    }
    else
    {
        Write-ScreenInfo -Type Error -Message 'Neither Credential nor AccessToken are available. Unable to continue'
        return
    }

    $defaultParam
}
