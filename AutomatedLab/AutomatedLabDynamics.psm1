function Install-LabDynamics
{
    [CmdletBinding()]
    param
    (
        [switch]
        $CreateCheckPoints
    )

    Write-LogFunctionEntry

    $lab = Get-Lab -ErrorAction Stop
    $vms = Get-LabVm -Role Dynamics
    $sql = Get-LabVm -Role SQLServer2016, SQLServer2017 | Sort-Object { $_.Roles.Name } | Select-Object -Last 1
    Start-LabVM -ComputerName $vms -Wait

    Invoke-LabCommand -ComputerName $vms -ScriptBlock {
        if (-not (Test-Path C:\DeployDebug))
        {
            $null = New-Item -ItemType Directory -Path C:\DeployDebug
        }
        if (-not (Test-Path C:\DynamicsSetup))
        {
            $null = New-Item -ItemType Directory -Path C:\DynamicsSetup
        }
    } -NoDisplay
    $someDc = Get-LabVm -Role RootDc | Select -First 1
    $defaultDomain = Invoke-LabCommand -ComputerName $someDc -ScriptBlock { Get-ADDomain } -PassThru -NoDisplay

    # Download prerequisites (which are surprisingly old...)
    Write-ScreenInfo -Message "Downloading and installing prerequisites on $($vms.Count) machines"
    $downloadTargetFolder = "$labSources\SoftwarePackages"
    $dynamicsUri = Get-LabConfigurationItem -Name Dynamics365Uri
    $cppRedist64_2013 = Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name cppredist64_2013) -Path $downloadTargetFolder -FileName vcredist_x64_2013.exe -PassThru -NoDisplay
    $cppRedist64_2010 = Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name cppredist64_2010) -Path $downloadTargetFolder -FileName vcredist_x64_2010.exe -PassThru -NoDisplay
    $odbc = Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name SqlOdbc13) -Path $downloadTargetFolder -FileName odbc2013.msi -PassThru -NoDisplay
    $sqlServerNativeClient2012 = Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name SqlServerNativeClient2012) -Path $downloadTargetFolder -FileName sqlncli2012.msi -PassThru -NoDisplay
    $sqlClrType = Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name SqlClrType2016) -Path $downloadTargetFolder -FileName sqlclrtype2016.msi -PassThru -NoDisplay
    $sqlSmo = Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name SqlSmo2016) -Path $downloadTargetFolder -FileName sqlsmo2016.msi -PassThru -NoDisplay
    $installer = Get-LabInternetFile -Uri $dynamicsUri -Path $labSources/SoftwarePackages -PassThru -NoDisplay
    Install-LabSoftwarePackage -ComputerName $vms -Path $installer.FullName -CommandLine '/extract:C:\DynamicsSetup /quiet' -NoDisplay
    Install-LabSoftwarePackage -Path  $cppRedist64_2010.FullName -Computer $vms -CommandLine '/quiet' -NoDisplay
    Install-LabSoftwarePackage -Path  $cppRedist64_2013.FullName -Computer $vms -CommandLine '/s' -NoDisplay
    Install-LabSoftwarePackage -Path $odbc.FullName -ComputerName $vms -CommandLine '/QN ADDLOCAL=ALL IACCEPTMSODBCSQLLICENSETERMS=YES /L*v C:\odbc.log' -NoDisplay
    Install-LabSoftwarePackage -Path $sqlServerNativeClient2012.FullName -ComputerName $vms -CommandLine '/QN IACCEPTSQLNCLILICENSETERMS=YES' -NoDisplay
    Install-LabSoftwarePackage -Path $sqlClrType.FullName -ComputerName $vms -NoDisplay
    Install-LabSoftwarePackage -Path $sqlSmo.FullName -ComputerName $vms -NoDisplay
    
    [xml]$defaultXml = @"
    <CRMSetup>  
    <Server>  
    <Patch update="false" />
    <LicenseKey>KKNV2-4YYK8-D8HWD-GDRMW-29YTW</LicenseKey>
    <SqlServer>$sql</SqlServer>  
    <Database create="true"/>  
    <Reporting URL="http://$sql/ReportServer"/>  
    <OrganizationCollation>Latin1_General_CI_AI</OrganizationCollation>  
    <basecurrency isocurrencycode="USD" currencyname="US Dollar" currencysymbol="$" currencyprecision="2"/>  
    <Organization>AutomatedLab</Organization>  
    <OrganizationUniqueName>automatedlab</OrganizationUniqueName>
    <WebsiteUrl create="true" port="5555"> </WebsiteUrl>  
    <InstallDir>c:\Program Files\Microsoft Dynamics CRM</InstallDir>      
    <CrmServiceAccount type="DomainUser">  
      <ServiceAccountLogin>$($defaultDomain.Name)\CRMAppService</ServiceAccountLogin>  
      <ServiceAccountPassword>$($lab.DefaultInstallationCredential.Password)</ServiceAccountPassword>  
    </CrmServiceAccount>      
    <SandboxServiceAccount type="DomainUser">
      <ServiceAccountLogin>$($defaultDomain.Name)\CRMSandboxService</ServiceAccountLogin>  
      <ServiceAccountPassword>$($lab.DefaultInstallationCredential.Password)</ServiceAccountPassword>  
    </SandboxServiceAccount>        
    <DeploymentServiceAccount type="DomainUser">  
      <ServiceAccountLogin>$($defaultDomain.Name)\CRMDeploymentService</ServiceAccountLogin>  
      <ServiceAccountPassword>$($lab.DefaultInstallationCredential.Password)</ServiceAccountPassword>  
    </DeploymentServiceAccount>        
    <AsyncServiceAccount type="DomainUser">  
      <ServiceAccountLogin>$($defaultDomain.Name)\CRMAsyncService</ServiceAccountLogin>  
      <ServiceAccountPassword>$($lab.DefaultInstallationCredential.Password)</ServiceAccountPassword>  
    </AsyncServiceAccount>        
    <VSSWriterServiceAccount type="DomainUser">   
      <ServiceAccountLogin>$($defaultDomain.Name)\CRMVSSWriterService</ServiceAccountLogin>  
      <ServiceAccountPassword>$($lab.DefaultInstallationCredential.Password)</ServiceAccountPassword>  
    </VSSWriterServiceAccount>        
    <MonitoringServiceAccount type="DomainUser">  
      <ServiceAccountLogin>$($defaultDomain.Name)\CRMMonitoringService</ServiceAccountLogin>  
      <ServiceAccountPassword>$($lab.DefaultInstallationCredential.Password)</ServiceAccountPassword>  
    </MonitoringServiceAccount>  
      
      <SQM optin="false"/>  
     <muoptin optin="false"/>  
      
     <Groups AutoGroupManagementOff="false">  
     <PrivUserGroup>CN=PrivUserGroup,OU=CRM,$($defaultDomain.DistinguishedName)</PrivUserGroup>  
     <SQLAccessGroup>CN=SQLAccessGroup,OU=CRM,$($defaultDomain.DistinguishedName)</SQLAccessGroup>  
     <ReportingGroup>CN=ReportingGroup,OU=CRM,$($defaultDomain.DistinguishedName)</ReportingGroup>  
     <PrivReportingGroup>CN=PrivReportingGroup,OU=CRM,$($defaultDomain.DistinguishedName)</PrivReportingGroup>  
    </Groups> 
     </Server>  
    </CRMSetup>
"@
    [xml]$frontendRole = @"
<RoleConfig>
<Roles>  
    <Role Name="WebApplicationServer" />  
    <Role Name="OrganizationWebService" />  
    <Role Name="DiscoveryWebService" />  
    <Role Name="HelpServer" />  
</Roles> 
</RoleConfig>
"@
    [xml]$backendRole = @"
    <RoleConfig>
<Roles>  
    <Role Name="AsynchronousProcessingService" />  
    <Role Name="EmailConnector" />  
    <Role Name="SandboxProcessingService" /> 
</Roles> 
</RoleConfig>
"@
    [xml]$adminRole = @"
    <RoleConfig>
<Roles>  
    <Role Name="DeploymentTools" />  
    <Role Name="DeploymentWebService" />  
    <Role Name="VSSWriter" />
</Roles>
</RoleConfig>
"@

    Write-ScreenInfo -Message "Installing Dynamics 365 CRM on $($vms.Count) machines"
    $orgFirstDeployed = @{ }

    foreach ($vm in $vms)
    {
        $role = $vm.Roles | Where-Object { $_.Name -band [AutomatedLab.Roles]::Dynamics }
        $serverXml = $defaultXml.Clone()

        foreach ($property in $role.Properties.Keys)
        {
            switch ($property.Key)
            {
                'SqlServer'
                { 
                    $sql = Get-LabVm -ComputerName $property.Value
                    $serverXml.CRMSetup.Server.SqlServer = $property.Value 
                }
                'ReportingUrl' { $serverXml.CRMSetup.Server.Reporting.URL = $property.Value }
                'OrganizationCollation' { $serverXml.CRMSetup.Server.OrganizationCollation = $property.Value }
                'IsoCurrencyCode' { $serverXml.CRMSetup.Server.basecurrency.isocurrencycode = $property.Value }
                'CurrencyName' { $serverXml.CRMSetup.Server.currencyname.isocurrencycode = $property.Value }
                'CurrencySymbol' { $serverXml.CRMSetup.Server.basecurrency.currencysymbol = $property.Value }
                'CurrencyPrecision' { $serverXml.CRMSetup.Server.basecurrency.currencyprecision = $property.Value }
                'Organization' { $serverXml.CRMSetup.Server.Organization = $property.Value }
                'OrganizationUniqueName' { $serverXml.CRMSetup.Server.OrganizationUniqueName = $property.Value }
                'CrmServiceAccount' { $serverXml.CRMSetup.Server.CrmServiceAccount.ServiceAccountLogin = $property.Value }
                'SandboxServiceAccount' { $serverXml.CRMSetup.Server.SandboxServiceAccount.ServiceAccountLogin = $property.Value }
                'DeploymentServiceAccount' { $serverXml.CRMSetup.Server.DeploymentServiceAccount.ServiceAccountLogin = $property.Value }
                'AsyncServiceAccount' { $serverXml.CRMSetup.Server.AsyncServiceAccount.ServiceAccountLogin = $property.Value }
                'VSSWriterServiceAccount' { $serverXml.CRMSetup.Server.VSSWriterServiceAccount.ServiceAccountLogin = $property.Value }
                'MonitoringServiceAccount' { $serverXml.CRMSetup.Server.MonitoringServiceAccount.ServiceAccountLogin = $property.Value }
                'CrmServiceAccountPassword' { $serverXml.CRMSetup.Server.CrmServiceAccount.ServiceAccountPassword = $property.Value }
                'SandboxServiceAccountPassword' { $serverXml.CRMSetup.Server.SandboxServiceAccount.ServiceAccountPassword = $property.Value }
                'DeploymentServiceAccountPassword' { $serverXml.CRMSetup.Server.DeploymentServiceAccount.ServiceAccountPassword = $property.Value }
                'AsyncServiceAccountPassword' { $serverXml.CRMSetup.Server.AsyncServiceAccount.ServiceAccountPassword = $property.Value }
                'VSSWriterServiceAccountPassword' { $serverXml.CRMSetup.Server.VSSWriterServiceAccount.ServiceAccountPassword = $property.Value }
                'MonitoringServiceAccountPassword' { $serverXml.CRMSetup.Server.MonitoringServiceAccount.ServiceAccountPassword = $property.Value }
                'IncomingExchangeServer'
                {
                    $node = $serverXml.CreateElement('Email')
                    $incoming = $serverXml.CreateElement('IncomingExchangeServer')
                    $attr = $serverXml.CreateAttribute('name')
                    $attr.InnerText = $property.Value
                    $null = $incoming.Attributes.Append($attr)
                    $null = $node.AppendChild($incoming)
                    $null = $serverXml.CRMSetup.Server.AppendChild($node)
                }
                'PrivUserGroup' { $serverXml.CRMSetup.Server.Groups.PrivUserGroup = $property.Value }
                'SQLAccessGroup' { $serverXml.CRMSetup.Server.Groups.SQLAccessGroup = $property.Value }
                'ReportingGroup' { $serverXml.CRMSetup.Server.Groups.ReportingGroup = $property.Value }
                'PrivReportingGroup' { $serverXml.CRMSetup.Server.Groups.PrivReportingGroup = $property.Value }
                'LicenseKey'
                {
                    $node = $serverXml.CreateElement('LicenseKey')
                    $node.InnerText = $property.Value
                    $null = $serverXml.CRMSetup.Server.AppendChild($node)
                }
            }
        }

        if ($orgFirstDeployed.Contains($serverXml.CRMSetup.Server.OrganizationUniqueName))
        {
            $serverXml.CRMSetup.Server.Database.create = 'False'
        }

        if (-not $orgFirstDeployed.Contains($serverXml.CRMSetup.Server.OrganizationUniqueName))
        {
            $orgFirstDeployed[$serverXml.CRMSetup.Server.OrganizationUniqueName] = $vm.Name
        }

        if ($role.Name -eq [AutomatedLab.Roles]::DynamicsFrontend)
        {
            $lab.AzureSettings.LoadBalancerPortCounter++
            $remotePort = $lab.AzureSettings.LoadBalancerPortCounter
            Write-ScreenInfo -Message ('Connection to dynamics frontend via http://{0}:{1}' -f $vm.AzureConnectionInfo.DnsName, $remotePort)
            Add-LWAzureLoadBalancedPort -ComputerName $vm -DestinationPort $serverXml.CRMSetup.Server.WebsiteUrl.port -Port $remotePort
            $node = $serverXml.ImportNode($frontendRole.RoleConfig, $true)
            $null = $serverXml.CRMSetup.Server.AppendChild($node.Roles)
        }
        if ($role.Name -eq [AutomatedLab.Roles]::DynamicsBackend)
        {
            $node = $serverXml.ImportNode($backendRole.RoleConfig, $true)
            $null = $serverXml.CRMSetup.Server.AppendChild($node.Roles)
        }
        if ($role.Name -eq [AutomatedLab.Roles]::DynamicsAdmin)
        {
            $node = $serverXml.ImportNode($adminRole.RoleConfig, $true)
            $null = $serverXml.CRMSetup.Server.AppendChild($node.Roles)
        }

        # Begin AD Prep
        [hashtable[]] $users = foreach ($node in $serverXml.SelectNodes('/CRMSetup/Server/*[contains(name(), "Account")]'))
        {
            @{
                Name            = $node.ServiceAccountLogin -replace '.*\\'
                AccountPassword = ConvertTo-SecureString -String $node.ServiceAccountPassword -AsPlainText -Force
                Enabled         = $true
                ErrorAction     = 'Stop'
            }
        }

        [hashtable[]] $groups = foreach ($node in $serverXml.SelectNodes('/CRMSetup/Server/Groups/*[contains(name(), "Group")]'))
        {
            $null = $node.InnerText -match 'CN=(\w+),OU'
            @{
                Name          = $Matches.1
                GroupScope    = 'DomainLocal'
                GroupCategory = 'Security'
                Path          = $node.InnerText -replace 'CN=\w+,'
                ErrorAction   = 'Stop'
            }
        }

        $ous = $groups.Path | Sort-Object -Unique

        $sqlRole = $sql.Roles | Where-Object { $_.Name -band [AutomatedLab.Roles]::SQLServer }

        $memberships = @{
            $serverXml.CRMSetup.Server.Groups.PrivUserGroup      = @(
                $serverXml.CRMSetup.Server.CrmServiceAccount.ServiceAccountLogin
                $serverXml.CRMSetup.Server.DeploymentServiceAccount.ServiceAccountLogin
                $serverXml.CRMSetup.Server.AsyncServiceAccount.ServiceAccountLogin
                $serverXml.CRMSetup.Server.VSSWriterServiceAccount.ServiceAccountLogin
                ($sqlRole.Properties.GetEnumerator | Where-Object Key -like *Account).Value
            )
            $serverXml.CRMSetup.Server.Groups.SQLAccessGroup     = @(
                $serverXml.CRMSetup.Server.CrmServiceAccount.ServiceAccountLogin
                $serverXml.CRMSetup.Server.DeploymentServiceAccount.ServiceAccountLogin
                $serverXml.CRMSetup.Server.AsyncServiceAccount.ServiceAccountLogin
                $serverXml.CRMSetup.Server.VSSWriterServiceAccount.ServiceAccountLogin
                ($sqlRole.Properties.GetEnumerator | Where-Object Key -like *Account).Value
            )
            $serverXml.CRMSetup.Server.Groups.ReportingGroup     = @(
                $lab.DefaultInstallationCredential.UserName
            )
            $serverXml.CRMSetup.Server.Groups.PrivReportingGroup = @(
                ($sqlRole.Properties.GetEnumerator | Where-Object Key -like *Account).Value
            )
        }

        Invoke-LabCommand -ActivityName 'Enabling SQL Server Agent' -ComputerName $sql -ScriptBlock {
            Get-Service -Name *SQLSERVERAGENT* | Set-Service -StartupType Automatic -Status Running
        } -NoDisplay

        Invoke-LabCommand -ActivityName 'Preparing accounts, groups and OUs' -ComputerName $someDc -ScriptBlock {
            foreach ($ou in $ous)
            {
                $null = $ou -match '^OU=(?<Name>\w+),'
                $ouName = $Matches.Name
                $path = $ou -replace '^OU=(\w+),'
                try
                {
                    New-ADOrganizationalUnit -Name $ouName -Path $path -ErrorAction Stop
                }
                catch {}
            }

            foreach ($user in $users)
            {
                try
                {
                    New-ADUser @user
                }
                catch {}
            }

            foreach ($group in $groups)
            {
                try
                {
                    New-ADGroup @group
                }
                catch {}
            }

            foreach ($membership in $memberships.GetEnumerator())
            {
                if (-not $membership.Value) { continue }
                Add-ADGroupMember -Identity $membership.Key -Members ($membership.Value -replace '.*\\' | Where-Object { $_ })
            }
        } -Variable (Get-Variable groups, ous, users, memberships) -NoDisplay

        Invoke-LabCommand -ComputerName $vm -ScriptBlock {
            # Using SID instead of name 'Performance Log Users' to avoid possible translation issues
            Add-LocalGroupMember -SID 'S-1-5-32-559' -Member $serverxml.crmsetup.Server.AsyncServiceAccount.ServiceAccountLogin, $serverxml.crmsetup.Server.CrmServiceAccount.ServiceAccountLogin
            $serverXml.Save('C:\DeployDebug\Dynamics.xml')
        } -Variable (Get-Variable serverXml) -NoDisplay
    }

    Restart-LabVM -ComputerName $vms -Wait -NoDisplay

    $timeout = if ($lab.DefaultVirtualizationEngine -eq 'Azure') { 60 } else { 45 }
    Install-LabSoftwarePackage -ComputerName $orgFirstDeployed.Values -LocalPath 'C:\DynamicsSetup\SetupServer.exe' -CommandLine '/config C:\DeployDebug\Dynamics.xml /log C:\DeployDebug\DynamicsSetup.log /Q' -ExpectedReturnCodes 0, 3010 -NoDisplay -UseShellExecute -AsScheduledJob -UseExplicitCredentialsForScheduledJob -Timeout $timeout

    $remainingVms = $vms | Where-Object -Property Name -notin $orgFirstDeployed.Values
    if ($remainingVms)
    {
        Install-LabSoftwarePackage -ComputerName $remainingVms -LocalPath 'C:\DynamicsSetup\SetupServer.exe' -CommandLine '/config C:\DeployDebug\Dynamics.xml /log C:\DeployDebug\DynamicsSetup.log /Q' -ExpectedReturnCodes 0, 3010 -NoDisplay -UseShellExecute -AsScheduledJob -UseExplicitCredentialsForScheduledJob -Timeout $timeout
    }

    if ($CreateCheckPoints.IsPresent)
    {
        Checkpoint-LabVM -ComputerName $vms -SnapshotName AfterDynamicsInstall
    }

    Write-LogFunctionExit
}
