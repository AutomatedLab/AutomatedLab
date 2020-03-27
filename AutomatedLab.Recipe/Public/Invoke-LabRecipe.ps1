function Invoke-LabRecipe
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'ByName')]
        [string]
        $Name,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ByRecipe')]
        [object]
        $Recipe,

        [Parameter()]
        [ValidateSet('HyperV', 'Azure', 'VMWare')]
        [string]
        $DefaultVirtualizationEngine,

        [Parameter()]
        [pscredential]
        $LabCredential,

        [Parameter()]
        [AutomatedLab.OperatingSystem]
        $DefaultOperatingSystem,

        [Parameter()]
        [AutomatedLab.IpNetwork]
        $DefaultAddressSpace,

        [Parameter()]
        [string]
        $DefaultDomainName,

        [Parameter()]
        [string]
        $OutFile,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [switch]
        $NoDeploy
    )

    process
    {
        if ($Name)
        {
            $Recipe = Get-LabRecipe -Name $Name
        }

        $Recipe.DefaultVirtualizationEngine = if ($DefaultVirtualizationEngine) {$DefaultVirtualizationEngine} elseif ($null -ne $Recipe.DefaultVirtualizationEngine) {$Recipe.DefaultVirtualizationEngine} else {'HyperV'}
        $Recipe.DefaultDomainName = if ($DefaultDomainName) {$DefaultDomainName} elseif ($null -ne $Recipe.DefaultDomainName) {$Recipe.DefaultDomainName} else {'contoso.com'}
        $Recipe.DefaultAddressSpace = if ($DefaultAddressSpace) {$DefaultAddressSpace.ToString()} elseif ($null -ne $Recipe.DefaultAddressSpace) {$Recipe.DefaultAddressSpace} else {(Get-LabAvailableAddresseSpace).ToString()}
        $Recipe.DefaultOperatingSystem = if ($DefaultOperatingSystem) {$DefaultOperatingSystem.OperatingSystemName} elseif ($null -ne $Recipe.DefaultOperatingSystem) {$Recipe.DefaultOperatingSystem} else {'Windows Server 2016 Datacenter'}
        $Recipe.VmPrefix = if ($VmPrefix) {$VmPrefix} elseif ($null -ne $Recipe.VmPrefix) {$Recipe.VmPrefix} else {(1..4 | ForEach-Object { [char[]](65..90) | Get-Random }) -join ''}

        $scriptContent = [System.Text.StringBuilder]::new()
        $null = $scriptContent.AppendLine("New-LabDefinition -Name $($Recipe.Name) -DefaultVirtualizationEngine $($Recipe.DefaultVirtualizationEngine)")
        $null = $scriptContent.AppendLine("Add-LabVirtualNetworkDefinition -Name $($Recipe.Name) -AddressSpace $($Recipe.DefaultAddressSpace)")
        $null = $scriptContent.AppendLine("`$PSDefaultParameterValues.Clear()")
        $null = $scriptContent.AppendLine("`$PSDefaultParameterValues.Add('Add-LabMachineDefinition:Network', '$($Recipe.Name)')")
        $null = $scriptContent.AppendLine("`$PSDefaultParameterValues.Add('Add-LabMachineDefinition:OperatingSystem', '$($Recipe.DefaultOperatingSystem)')")

        foreach ($requiredIso in $Recipe.RequiredProductIsos)
        {
            switch ($requiredIso)
            {
                'CI_CD' {$isoPattern = 'team_foundation'; $isoName = 'Tfs2017'}
                'SQL' {$isoPattern = 'sql_server_2017'; $isoName = 'SQLServer2017'}
            }

            $isoFile = Get-ChildItem -Path "$(Get-LabSourcesLocationInternal -Local)\ISOs\*$isoPattern*" | Sort-Object -Property CreationTime | Select-Object -Last 1 -ExpandProperty FullName
            if (-not $isoFile)
            {
                $isoFile = Read-Host -Prompt "Please provide the full path to an ISO for $isoName"
            }

            $null = $scriptContent.AppendLine("Add-LabIsoImageDefinition -Name $isoName -Path $isoFile")
        }

        if (-not $Credential)
        {
            $Credential = New-Object -TypeName pscredential -ArgumentList 'Install', ('Somepass1' | ConvertTo-SecureString -AsPlainText -Force)
        }

        $null = $scriptContent.AppendLine("Set-LabInstallationCredential -UserName $($Credential.UserName) -Password $($Credential.GetNetworkCredential().Password)")

        if ($Recipe.DeployRole -contains 'Domain' -or $Recipe.DeployRole -contains 'Exchange')
        {
            $null = $scriptContent.AppendLine("Add-LabDomainDefinition -Name $($Recipe.DefaultDomainName) -AdminUser $($Credential.UserName) -AdminPassword $($Credential.GetNetworkCredential().Password)")
            $null = $scriptContent.AppendLine("`$PSDefaultParameterValues.Add('Add-LabMachineDefinition:DomainName', '$($Recipe.DefaultDomainName)')")
            $null = $scriptContent.AppendLine("Add-LabMachineDefinition -Name $($Recipe.VmPrefix)DC1 -Roles RootDC")
        }

        if ($Recipe.DeployRole -contains 'PKI')
        {
            $null = $scriptContent.AppendLine("Add-LabMachineDefinition -Name $($Recipe.VmPrefix)CA1 -Roles CARoot")
        }

        if ($Recipe.DeployRole -contains 'Exchange')
        {
            $null = $scriptContent.AppendLine('$role = Get-LabPostInstallationActivity -CustomRole Exchange2016')
            $null = $scriptContent.AppendLine("Add-LabMachineDefinition -Name $($Recipe.VmPrefix)EX1 -PostInstallationActivity `$role")
        }

        if ($Recipe.DeployRole -contains 'SQL' -or $Recipe.DeployRole -contains 'CI/CD')
        {
            $null = $scriptContent.AppendLine("Add-LabMachineDefinition -Name $($Recipe.VmPrefix)SQL1 -Roles SQLServer2017")
        }

        if ($Recipe.DeployRole -contains 'CI/CD')
        {
            $null = $scriptContent.AppendLine("Add-LabMachineDefinition -Name $($Recipe.VmPrefix)CICD1 -Roles Tfs2017")
        }

        if ($Recipe.DeployRole -contains 'DSCPull')
        {
            $engine = if ($Recipe.DefaultOperatingSystem -like '*2019*') {'sql'} else {'mdb'}
            $null = $scriptContent.AppendLine("`$role = Get-LabMachineRoleDefinition -Role DSCPullServer -Properties @{DoNotPushLocalModules = 'true'; DatabaseEngine = '$engine'; SqlServer = '$($Recipe.VmPrefix)SQL1'; DatabaseName = 'DSC' }")
            $null = $scriptContent.AppendLine("Add-LabMachineDefinition -Name $($Recipe.VmPrefix)PULL01 -Roles `$role")
        }

        $null = $scriptContent.AppendLine('Install-Lab')
        $null = $scriptContent.AppendLine('Show-LabDeploymentSummary -Detailed')
        $labBlock = [scriptblock]::Create($scriptContent.ToString())

        if ($OutFile)
        {
            $scriptContent.ToString() | Set-Content -Path $OutFile -Force -Encoding UTF8
        }

        if ($PassThru) {$labBlock}
        if ($NoDeploy) { return }

        if ($PSCmdlet.ShouldProcess($Recipe.Name, "Deploying lab"))
        {
            & $labBlock
        }
    }
}
