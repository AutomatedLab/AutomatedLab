# Support functions for the opt-in live Proxmox tests. Dot-source this file; it defines functions only.
# The pure functions (naming, template classification and selection, connection input) are unit-tested in
# Tests/Unit/LiveTests. Functions that talk to Proxmox are exercised only by the live run.

function Get-ProxmoxLiveTestSetting
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()

    @{
        Port          = 8006
        VmTag         = 'al-live-test'
        VmNamePrefix  = 'allive'
        VmNamePattern = '^allive-[0-9a-f]{8}-\d{1,2}$'
    }
}

function New-ProxmoxLiveTestRunId
{
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    [guid]::NewGuid().ToString('N').Substring(0, 8)
}

function New-ProxmoxLiveTestVmName
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-f]{8}$')]
        [string]$RunId,

        [Parameter(Mandatory)]
        [ValidateRange(1, 99)]
        [int]$Index
    )

    '{0}-{1}-{2}' -f (Get-ProxmoxLiveTestSetting).VmNamePrefix, $RunId, $Index
}

function Test-ProxmoxLiveTestApiToken
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$ApiToken
    )

    if ([string]::IsNullOrEmpty($ApiToken))
    {
        return $false
    }

    # The same pattern Connect-LabProxmoxCluster applies. That function echoes a malformed token in its error
    # message, so the token is checked here, before it can reach the console.
    $ApiToken -match '^[^@\s]+@[^!\s]+![^=\s]+=[^\s]+$'
}

function ConvertFrom-ProxmoxLiveTestSecureString
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory)]
        [securestring]$SecureString
    )

    [System.Net.NetworkCredential]::new([string]::Empty, $SecureString).Password
}

function ConvertTo-ProxmoxLiveTestTemplateInfo
{
    <#
    .SYNOPSIS
        Classifies a Proxmox VM as an AutomatedLab template for the live tests.

    .DESCRIPTION
        AutomatedLab treats a VM as a template when its template flag is set and it carries the tag 'template'.
        The operating system is the first other tag that is not a version number (for example
        'windowsserver2025datacenterdesktopexperience'). This function applies the same rule and maps the
        operating system tag to the releases the live tests support: Windows 10, Windows 11 and Windows Server
        2019, 2022 and 2025.

    .PARAMETER Template
        A VM object as returned by Get-LWProxmoxVM: name, vmid, node, template and tags.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$Template
    )

    begin
    {
        $catalog = @(
            @{ Pattern = '^windowsserver2025'; Family = 'Server'; Release = '2025' }
            @{ Pattern = '^windowsserver2022'; Family = 'Server'; Release = '2022' }
            @{ Pattern = '^windowsserver2019'; Family = 'Server'; Release = '2019' }
            @{ Pattern = '^windows11'; Family = 'Client'; Release = '11' }
            @{ Pattern = '^windows10'; Family = 'Client'; Release = '10' }
        )
    }

    process
    {
        $tags = @($Template.tags)
        if ($Template.tags -is [string])
        {
            $tags = @($Template.tags -split ';')
        }
        $tags = @($tags | Where-Object { $_ })

        $versionTag = $tags | Where-Object { $_ -match '^\d+(\.\d+){1,3}$' } | Select-Object -First 1
        $osTag = $tags | Where-Object { $_ -ne 'template' -and $_ -ne $versionTag } | Select-Object -First 1

        $flagSet = [int]$Template.template -eq 1
        $tagSet = $tags -contains 'template'
        $isTemplate = $flagSet -and $tagSet

        $family = $null
        $release = $null
        $reason = $null

        if (-not $flagSet)
        {
            $reason = 'not a template (the template flag is not set)'
        }
        elseif (-not $tagSet)
        {
            $reason = "the VM is missing the 'template' tag, so AutomatedLab ignores it"
        }
        elseif (-not $osTag)
        {
            $reason = "no operating system tag (a tag other than 'template' and the version)"
        }
        else
        {
            $entry = $catalog | Where-Object { $osTag -match $_.Pattern } | Select-Object -First 1
            if ($entry)
            {
                $family = $entry.Family
                $release = $entry.Release
            }
            else
            {
                $reason = "the operating system tag '$osTag' is not in the supported list (Windows 10, Windows 11, Windows Server 2019, 2022, 2025)"
            }
        }

        $desktopExperience = $false
        if ($family -eq 'Client')
        {
            $desktopExperience = $true
        }
        elseif ($family -eq 'Server')
        {
            $desktopExperience = [bool]($osTag -match 'desktopexperience')
        }

        [pscustomobject]@{
            Name              = [string]$Template.name
            VmId              = [int]$Template.vmid
            Node              = [string]$Template.node
            Tags              = $tags
            OsTag             = $osTag
            VersionTag        = $versionTag
            IsTemplate        = $isTemplate
            Family            = $family
            Release           = $release
            DesktopExperience = $desktopExperience
            IsSupported       = $isTemplate -and [bool]$release
            Reason            = $reason
        }
    }
}

function Select-ProxmoxLiveTestTemplate
{
    <#
    .SYNOPSIS
        Chooses the templates a live run uses.

    .DESCRIPTION
        Without -Name the choice is one template per release, in this order: the newest server release, the
        newest client release, then the next newest releases until -Count is reached. A release is rated by
        approximate age: Server 2025, Windows 11, Server 2022, Windows 10, Server 2019. Within a release the
        Desktop Experience edition wins, then the node and the name decide, so the result is stable.
        With -Name exactly the named templates are returned, in the given order.

    .PARAMETER TemplateInfo
        Objects from ConvertTo-ProxmoxLiveTestTemplateInfo. Unsupported templates are ignored.

    .PARAMETER Count
        How many templates to select.

    .PARAMETER Name
        Template names to use instead of the automatic choice.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(ValueFromPipeline)]
        [object[]]$TemplateInfo,

        [Parameter()]
        [ValidateRange(1, 6)]
        [int]$Count = 2,

        [Parameter()]
        [string[]]$Name
    )

    begin
    {
        $collected = [System.Collections.Generic.List[object]]::new()
    }

    process
    {
        foreach ($item in $TemplateInfo)
        {
            if ($item)
            {
                $collected.Add($item)
            }
        }
    }

    end
    {
        $supported = @($collected | Where-Object { $_.IsSupported })

        $withReason = {
            param ($item, $reason)

            $item | Select-Object -Property * | Add-Member -NotePropertyName 'Selection' -NotePropertyValue $reason -PassThru
        }

        if ($Name)
        {
            foreach ($requested in $Name)
            {
                $match = $supported | Where-Object { $_.Name -eq $requested } | Select-Object -First 1
                if (-not $match)
                {
                    $available = if ($supported) { ($supported.Name | Sort-Object) -join ', ' } else { 'none' }
                    throw "Template '$requested' is not among the supported templates found on the host ($available)."
                }

                & $withReason $match 'requested by name'
            }

            return
        }

        $rank = @{ '2025' = 5; '11' = 4; '2022' = 3; '10' = 2; '2019' = 1 }

        $candidates = foreach ($group in ($supported | Group-Object -Property Release))
        {
            $group.Group |
                Sort-Object -Property @{ Expression = 'DesktopExperience'; Descending = $true }, 'Node', 'Name' |
                Select-Object -First 1
        }
        $candidates = @($candidates | Sort-Object -Property @{ Expression = { $rank[$_.Release] }; Descending = $true })

        $servers = @($candidates | Where-Object { $_.Family -eq 'Server' })
        $clients = @($candidates | Where-Object { $_.Family -eq 'Client' })

        $picked = [System.Collections.Generic.List[object]]::new()
        if ($servers)
        {
            $picked.Add((& $withReason $servers[0] 'newest server'))
        }
        elseif ($clients)
        {
            $picked.Add((& $withReason $clients[0] 'newest client'))
        }

        if ($Count -ge 2 -and $servers -and $clients)
        {
            $picked.Add((& $withReason $clients[0] 'newest client'))
        }

        foreach ($candidate in $candidates)
        {
            if ($picked.Count -ge $Count)
            {
                break
            }

            if ($picked.Release -notcontains $candidate.Release)
            {
                $picked.Add((& $withReason $candidate 'next newest release'))
            }
        }

        $picked | Select-Object -First $Count
    }
}

function Resolve-ProxmoxLiveTestConnection
{
    <#
    .SYNOPSIS
        Collects and validates the Proxmox connection data for a live run.

    .DESCRIPTION
        Takes the host (name or IPv4 address), the port and either a credential (user and password) or an API
        token. Whatever is missing is asked for interactively, unless -NonInteractive is set. Secrets stay
        SecureString or PSCredential objects in memory; error messages never contain them.

    .PARAMETER HostName
        Host name or IPv4 address of a Proxmox node, without scheme, port or path.

    .PARAMETER Port
        API port. Defaults to 8006.

    .PARAMETER Credential
        User (for example root@pam) and password.

    .PARAMETER ApiToken
        API token in the format USER@REALM!TOKENID=UUID, as a SecureString.

    .PARAMETER NonInteractive
        Fail instead of prompting for missing values.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter()]
        [string]$HostName,

        [Parameter()]
        [ValidateRange(1, 65535)]
        [int]$Port = 8006,

        [Parameter()]
        [pscredential]$Credential,

        [Parameter()]
        [securestring]$ApiToken,

        [Parameter()]
        [switch]$NonInteractive
    )

    if ($Credential -and $ApiToken)
    {
        throw 'Specify either -Credential or -ApiToken, not both.'
    }

    if (-not $HostName)
    {
        if ($NonInteractive)
        {
            throw 'No Proxmox host: pass -HostName (host name or IPv4 address).'
        }

        $HostName = ([string](Read-Host -Prompt 'Proxmox host name or IP address')).Trim()
    }

    # The value is never echoed: a pasted URL could carry credentials.
    if ($HostName -notmatch '^[A-Za-z0-9]([A-Za-z0-9.\-]*[A-Za-z0-9])?$')
    {
        throw 'The Proxmox host must be a plain host name or IPv4 address, without scheme, user, port or path.'
    }

    if (-not $Credential -and -not $ApiToken)
    {
        if ($NonInteractive)
        {
            throw 'No Proxmox credentials: pass -Credential (user name and password) or -ApiToken (USER@REALM!TOKENID=UUID).'
        }

        $answer = ([string](Read-Host -Prompt 'Authenticate with an API token (T) or user name and password (P)? [T/P]')).Trim().ToUpperInvariant()
        switch ($answer)
        {
            'T'
            {
                $ApiToken = Read-Host -Prompt 'API token (USER@REALM!TOKENID=UUID)' -AsSecureString
            }
            'P'
            {
                $Credential = Get-Credential -Message 'Proxmox user name (for example root@pam) and password'
            }
            default
            {
                throw 'Answer T or P.'
            }
        }

        if (-not $Credential -and -not $ApiToken)
        {
            throw 'No credentials were entered.'
        }
    }

    $principal = $null
    $userName = $null
    if ($ApiToken)
    {
        $plainToken = ConvertFrom-ProxmoxLiveTestSecureString -SecureString $ApiToken
        $tokenValid = Test-ProxmoxLiveTestApiToken -ApiToken $plainToken
        if ($tokenValid)
        {
            # Only the part before '=' (USER@REALM!TOKENID) is shown; the secret follows it.
            $principal = $plainToken.Substring(0, $plainToken.IndexOf('='))
        }
        $plainToken = $null

        if (-not $tokenValid)
        {
            throw 'The API token is not in the format USER@REALM!TOKENID=UUID.'
        }
    }
    else
    {
        $userName = $Credential.UserName
        $principal = $userName
    }

    $authType = 'Credential'
    if ($ApiToken)
    {
        $authType = 'ApiToken'
    }

    [pscustomobject]@{
        HostName   = $HostName
        Port       = $Port
        AuthType   = $authType
        UserName   = $userName
        Principal  = $principal
        Credential = $Credential
        ApiToken   = $ApiToken
    }
}

function Test-ProxmoxLiveTestPrerequisite
{
    <#
    .SYNOPSIS
        Checks that everything the live tests need is installed. Installs nothing.

    .DESCRIPTION
        Returns one object per requirement: Name, Required, Found, Ok and Detail. Pester 5.3 or later, the
        Proxmox API module and the modules that make up AutomatedLab must be discoverable on the module path.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param ()

    $labHint = 'Install or build AutomatedLab, or pass -ModulePath with the folder that holds the built modules (for example publish).'
    $requirements = @(
        @{ Name = 'Pester'; Minimum = [version]'5.3.0'; Hint = 'Install Pester 5.3 or later: Install-Module Pester -MinimumVersion 5.3.0 -Scope CurrentUser.' }
        @{ Name = 'Corsinvest.ProxmoxVE.Api'; Hint = 'Install it: Install-Module Corsinvest.ProxmoxVE.Api -Scope CurrentUser.' }
        @{ Name = 'PSFramework'; Hint = 'Install it: Install-Module PSFramework -Scope CurrentUser.' }
        @{ Name = 'AutomatedLab.Common'; Hint = 'Install it: Install-Module AutomatedLab.Common -Scope CurrentUser.' }
        @{ Name = 'PSLog'; Hint = $labHint }
        @{ Name = 'AutomatedLabUnattended'; Hint = $labHint }
        @{ Name = 'PSFileTransfer'; Hint = $labHint }
        @{ Name = 'AutomatedLabDefinition'; Hint = $labHint }
        @{ Name = 'AutomatedLabWorker'; Hint = $labHint }
        @{ Name = 'AutomatedLabNotifications'; Hint = $labHint }
        @{ Name = 'AutomatedLabCore'; Hint = $labHint }
    )

    foreach ($requirement in $requirements)
    {
        $module = Get-Module -ListAvailable -Name $requirement.Name |
            Sort-Object -Property Version -Descending |
            Select-Object -First 1

        $found = $null
        if ($module)
        {
            $found = [string]$module.Version
        }

        $tooOld = $module -and $requirement.Minimum -and $module.Version -lt $requirement.Minimum

        $detail = ''
        if (-not $module)
        {
            $detail = "not found. $($requirement.Hint)"
        }
        elseif ($tooOld)
        {
            $detail = "version $found is too old. $($requirement.Hint)"
        }

        $required = 'any version'
        if ($requirement.Minimum)
        {
            $required = "$($requirement.Minimum) or later"
        }

        [pscustomobject]@{
            Name     = $requirement.Name
            Required = $required
            Found    = $found
            Ok       = [bool]$module -and -not $tooOld
            Detail   = $detail
        }
    }
}

function Import-ProxmoxLiveTestModule
{
    <#
    .SYNOPSIS
        Imports the modules the live tests use, in dependency order.

    .DESCRIPTION
        The umbrella module AutomatedLab is not imported: it requires Posh-SSH, which the live tests do not need.
    #>
    [CmdletBinding()]
    param ()

    $moduleNames = @(
        'PSFramework'
        'AutomatedLab.Common'
        'Corsinvest.ProxmoxVE.Api'
        'AutomatedLabUnattended'
        'PSLog'
        'PSFileTransfer'
        'AutomatedLabDefinition'
        'AutomatedLabWorker'
        'AutomatedLabNotifications'
        'AutomatedLabCore'
    )

    foreach ($moduleName in $moduleNames)
    {
        try
        {
            Import-Module -Name $moduleName -ErrorAction Stop
        }
        catch
        {
            throw "Could not import the module '$moduleName': $($_.Exception.Message)"
        }
    }
}

function Connect-ProxmoxLiveTestCluster
{
    <#
    .SYNOPSIS
        Connects AutomatedLab to the Proxmox cluster and proves that the API answers.

    .DESCRIPTION
        The token is converted to the plain string Connect-LabProxmoxCluster expects only for the call itself.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [object]$Connection
    )

    $parameters = @{
        HostName    = $Connection.HostName
        Port        = $Connection.Port
        ErrorAction = 'Stop'
    }

    if ($Connection.AuthType -eq 'ApiToken')
    {
        $plainToken = ConvertFrom-ProxmoxLiveTestSecureString -SecureString $Connection.ApiToken
        try
        {
            Connect-LabProxmoxCluster @parameters -ApiToken $plainToken
        }
        finally
        {
            $plainToken = $null
        }
    }
    else
    {
        Connect-LabProxmoxCluster @parameters -Credential $Connection.Credential
    }

    if (-not (Test-LabProxmoxConnection))
    {
        throw "Connected to '$($Connection.HostName):$($Connection.Port)', but the Proxmox API did not answer a version request."
    }
}

function Invoke-ProxmoxLiveTestWorkerCommand
{
    <#
    .SYNOPSIS
        Runs a script block in the scope of the AutomatedLabWorker module, where its private functions live.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [object[]]$ArgumentList
    )

    $module = Get-Module -Name AutomatedLabWorker
    if (-not $module)
    {
        throw 'The module AutomatedLabWorker is not loaded.'
    }

    & $module $ScriptBlock @ArgumentList
}

function Test-ProxmoxLiveTestCapability
{
    <#
    .SYNOPSIS
        Tells whether a command of the loaded AutomatedLabWorker module has a parameter.

    .DESCRIPTION
        A guard that tests the behavior a live test needs: an installed module that predates a change lacks its
        parameter, and the tests for that change are skipped instead of failing for the wrong reason.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter(Mandatory)]
        [string]$Parameter
    )

    try
    {
        $script = {
            param ($commandName, $parameterName)

            (Get-Command -Name $commandName -ErrorAction Stop).Parameters.ContainsKey($parameterName)
        }

        [bool](Invoke-ProxmoxLiveTestWorkerCommand -ScriptBlock $script -ArgumentList $Command, $Parameter)
    }
    catch
    {
        $false
    }
}

function Get-ProxmoxLiveTestLeftoverVm
{
    <#
    .SYNOPSIS
        Finds VMs that earlier live-test runs left behind.

    .DESCRIPTION
        Without -RunId a VM counts only when its name has the live-test form and it carries the live-test tag, so
        no other VM can be mistaken for one. With -RunId every VM named after that run is returned: the run created
        it, so the tag is not needed as proof.

    .PARAMETER RunId
        The eight-character id of one run.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidatePattern('^[0-9a-f]{8}$')]
        [string]$RunId
    )

    $settings = Get-ProxmoxLiveTestSetting
    $namePattern = $settings.VmNamePattern
    if ($RunId)
    {
        $namePattern = '^{0}-{1}-\d{{1,2}}$' -f $settings.VmNamePrefix, $RunId
    }

    Get-LWProxmoxVM -NoCache | Where-Object {
        $_.template -ne 1 -and
        $_.name -match $namePattern -and
        ($RunId -or (@($_.tags) -contains $settings.VmTag))
    }
}

function Remove-ProxmoxLiveTestVm
{
    <#
    .SYNOPSIS
        Removes a live-test VM.

    .DESCRIPTION
        Refuses every VM whose name does not have the live-test form. Remove-LWProxmoxVM then looks the VM up
        afresh and removes only the VMID given here.

    .PARAMETER Vm
        An object with Name and VmId, such as the output of New-ProxmoxLiveTestVm or Get-LWProxmoxVM.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$Vm
    )

    process
    {
        $vmName = [string]$Vm.Name
        $vmId = [int]$Vm.VmId

        if ($vmName -notmatch (Get-ProxmoxLiveTestSetting).VmNamePattern)
        {
            throw "Refusing to remove '$vmName': it is not a live-test VM name."
        }

        if ($PSCmdlet.ShouldProcess("$vmName (VMID $vmId)", 'Remove Proxmox VM'))
        {
            Remove-LWProxmoxVM -Name $vmName -VmId $vmId
        }
    }
}

function Get-ProxmoxLiveTestNextVmId
{
    <#
    .SYNOPSIS
        Returns a free VMID: the cluster's answer, or the highest VMID plus one.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param ()

    $reply = Get-PveClusterNextid
    if ($reply.StatusCode -eq 200 -and $reply.Response.data)
    {
        return [int]$reply.Response.data
    }

    $highest = Get-LWProxmoxVM -IncludeTemplates -NoCache | Measure-Object -Property vmid -Maximum
    if ($highest.Count -gt 0)
    {
        return [int]($highest.Maximum + 1)
    }

    throw "Could not determine a free VMID: the cluster answered '$($reply.StatusCode) $($reply.ReasonPhrase)' and no VM could be listed."
}

function Wait-ProxmoxLiveTestTask
{
    <#
    .SYNOPSIS
        Waits for a Proxmox task to stop and returns its exit status.

    .DESCRIPTION
        A failed status query is not fatal; polling continues until the timeout, and the last status and error
        are part of the timeout message.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory)]
        [string]$Node,

        [Parameter(Mandatory)]
        [string]$Upid,

        [Parameter()]
        [int]$TimeoutSeconds = 600
    )

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $lastStatus = ''
    $lastError = ''

    while ($true)
    {
        $reply = Get-PveNodesTasksStatus -Node $Node -Upid $Upid
        if ($reply.StatusCode -eq 200)
        {
            $lastStatus = [string]$reply.Response.data.status
            if ($lastStatus -eq 'stopped')
            {
                return [string]$reply.Response.data.exitstatus
            }
        }
        else
        {
            $lastError = "$($reply.StatusCode) $($reply.ReasonPhrase)"
        }

        if ($timer.Elapsed.TotalSeconds -ge $TimeoutSeconds)
        {
            throw "Proxmox task '$Upid' on node '$Node' did not finish within $TimeoutSeconds seconds (last status: '$lastStatus', last error: '$lastError')."
        }

        Start-Sleep -Seconds 2
    }
}

function New-ProxmoxLiveTestVm
{
    <#
    .SYNOPSIS
        Clones a template into a live-test VM and isolates it.

    .DESCRIPTION
        The clone is tagged and loses its network adapters, so a booted copy of a golden image can never clash
        with a machine on the lab network. The guest agent needs no network. A linked clone is made unless
        -FullClone or -Storage is given; linked clones cannot choose a storage, so -Storage implies a full clone.

    .PARAMETER Template
        An object with Name, VmId and Node, as returned by ConvertTo-ProxmoxLiveTestTemplateInfo.

    .PARAMETER Name
        The VM name; it must have the live-test form (see New-ProxmoxLiveTestVmName).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory)]
        [object]$Template,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [string]$Storage,

        [Parameter()]
        [switch]$FullClone,

        [Parameter()]
        [int]$TimeoutSeconds = 900
    )

    $settings = Get-ProxmoxLiveTestSetting
    if ($Name -notmatch $settings.VmNamePattern)
    {
        throw "'$Name' is not a live-test VM name (expected $($settings.VmNamePrefix)-<8 hex characters>-<number>)."
    }

    $newId = Get-ProxmoxLiveTestNextVmId

    $cloneParameters = @{
        Node        = $Template.Node
        Vmid        = $Template.VmId
        Newid       = $newId
        Name        = $Name
        Description = "AutomatedLab live test VM, cloned from template '$($Template.Name)'. Safe to delete."
    }
    if ($FullClone -or $Storage)
    {
        $cloneParameters.Full = $true
    }
    if ($Storage)
    {
        $cloneParameters.Storage = $Storage
    }

    $clone = New-PveNodesQemuClone @cloneParameters
    if ($clone.StatusCode -ne 200)
    {
        throw "Failed to clone template '$($Template.Name)' (VMID $($Template.VmId)) on node '$($Template.Node)' to '$Name': $($clone.ReasonPhrase)"
    }

    $exitStatus = Wait-ProxmoxLiveTestTask -Node $Template.Node -Upid ([string]$clone.Response.data) -TimeoutSeconds $TimeoutSeconds
    if ($exitStatus -ne 'OK' -and $exitStatus -notlike 'WARNINGS:*')
    {
        throw "The clone task for '$Name' (VMID $newId) ended with '$exitStatus'."
    }

    # Tag first and drop the adapters in the same call, so a clone is identifiable as soon as it can be touched.
    try
    {
        $config = Get-PveNodesQemuConfig -Node $Template.Node -Vmid $newId
        if ($config.StatusCode -ne 200)
        {
            throw "reading the configuration failed: $($config.ReasonPhrase)"
        }

        $update = @{
            Node = $Template.Node
            Vmid = $newId
            Tags = $settings.VmTag
        }
        $adapters = @($config.Response.data.PSObject.Properties.Name | Where-Object { $_ -match '^net\d+$' })
        if ($adapters)
        {
            $update.Delete = $adapters -join ','
        }

        $result = Set-PveNodesQemuConfig @update
        if ($result.StatusCode -ne 200)
        {
            throw "updating the configuration failed: $($result.ReasonPhrase)"
        }
    }
    catch
    {
        throw "The VM '$Name' (VMID $newId) was cloned but could not be prepared: $($_.Exception.Message). It still exists on node '$($Template.Node)'; the run removes it, or use -RemoveLeftovers."
    }

    [pscustomobject]@{
        Name         = $Name
        VmId         = $newId
        Node         = [string]$Template.Node
        TemplateName = [string]$Template.Name
        TemplateVmId = [int]$Template.VmId
    }
}

function Start-ProxmoxLiveTestVm
{
    <#
    .SYNOPSIS
        Starts a live-test VM and proves with a fresh lookup that it runs.

    .DESCRIPTION
        A task that ended with warnings is accepted when the VM is running afterwards, as Start-LWProxmoxVM does.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory)]
        [object]$Vm,

        [Parameter()]
        [int]$TimeoutSeconds = 600
    )

    $start = Start-PveVm -VmIdOrName $Vm.VmId
    if ($start.StatusCode -ne 200)
    {
        throw "Failed to start '$($Vm.Name)' (VMID $($Vm.VmId)): $($start.ReasonPhrase)"
    }

    $exitStatus = Wait-ProxmoxLiveTestTask -Node $Vm.Node -Upid ([string]$start.Response.data) -TimeoutSeconds $TimeoutSeconds

    $current = Get-LWProxmoxVM -ComputerName $Vm.Name -Node $Vm.Node -NoCache -ErrorAction Stop
    $running = $current.status -eq 'running' -and $current.CurrentStatus.qmpstatus -eq 'running'
    $taskFine = $exitStatus -eq 'OK' -or $exitStatus -like 'WARNINGS:*'

    if (-not $taskFine -or -not $running)
    {
        throw "The start task for '$($Vm.Name)' (VMID $($Vm.VmId)) ended with '$exitStatus' and the VM has status '$($current.status)', qmpstatus '$($current.CurrentStatus.qmpstatus)'."
    }

    $Vm
}

function Wait-ProxmoxLiveTestVmReady
{
    <#
    .SYNOPSIS
        Waits until a started clone can run commands and has finished its own first boot.

    .DESCRIPTION
        First the QEMU guest agent must run a trivial command, then Windows must report IMAGE_STATE_COMPLETE. A
        generalized template restarts while it specializes, which would otherwise surprise a test in the middle
        of a command.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [object]$Vm,

        [Parameter()]
        [int]$TimeoutSeconds = 600,

        [Parameter()]
        [int]$ImageStateTimeoutSeconds = 1800
    )

    $agentScript = {
        param ($node, $vmid, $name, $timeout)

        Wait-LWProxmoxGuestAgentReady -Node $node -Vmid $vmid -Name $name -TimeoutSeconds $timeout -RequireExec
    }
    $agentReady = @(Invoke-ProxmoxLiveTestWorkerCommand -ScriptBlock $agentScript -ArgumentList $Vm.Node, $Vm.VmId, $Vm.Name, $TimeoutSeconds)[-1]
    if (-not $agentReady)
    {
        throw "The QEMU guest agent on '$($Vm.Name)' (VMID $($Vm.VmId)) did not run commands within $TimeoutSeconds seconds. Check that the template has the guest agent installed and 'agent: 1' in its VM options."
    }

    $imageScript = {
        param ($node, $vmid, $name, $timeout)

        Wait-LWProxmoxWindowsImageStateComplete -Node $node -Vmid $vmid -Name $name -TimeoutSeconds $timeout
    }
    $imageReady = @(Invoke-ProxmoxLiveTestWorkerCommand -ScriptBlock $imageScript -ArgumentList $Vm.Node, $Vm.VmId, $Vm.Name, $ImageStateTimeoutSeconds)[-1]
    if (-not $imageReady)
    {
        throw "Windows on '$($Vm.Name)' (VMID $($Vm.VmId)) did not reach IMAGE_STATE_COMPLETE within $ImageStateTimeoutSeconds seconds. The clone may still be running its first-boot setup."
    }
}

function Get-ProxmoxLiveTestPlan
{
    <#
    .SYNOPSIS
        Inspects the connected Proxmox host and decides whether, and with which templates, a run can start.

    .DESCRIPTION
        Reads the nodes, the templates and the capabilities of the loaded AutomatedLab modules, and reports every
        reason that stops a run in Problems. The result holds no secret.

    .PARAMETER Connection
        The output of Resolve-ProxmoxLiveTestConnection, after the connection has been made.

    .PARAMETER TemplateCount
        How many templates a run uses.

    .PARAMETER MinimumTemplateCount
        How many usable templates must exist. It cannot exceed TemplateCount.

    .PARAMETER TemplateName
        Use exactly these templates; each must exist and be supported.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory)]
        [object]$Connection,

        [Parameter()]
        [int]$TemplateCount = 2,

        [Parameter()]
        [int]$MinimumTemplateCount = 2,

        [Parameter()]
        [string[]]$TemplateName
    )

    $problems = [System.Collections.Generic.List[string]]::new()

    $proxmoxVersion = $null
    try
    {
        $versionReply = Get-PveVersion
        if ($versionReply.StatusCode -eq 200)
        {
            $proxmoxVersion = [string]$versionReply.Response.data.version
        }
    }
    catch
    {
        Write-Verbose "Could not read the Proxmox version: $($_.Exception.Message)"
    }

    $nodes = @()
    try
    {
        $nodes = @(Get-LWProxmoxNode | ForEach-Object { [string]$_.node })
    }
    catch
    {
        $problems.Add("No usable Proxmox node was found: $($_.Exception.Message)")
    }
    if (-not $nodes -and $problems.Count -eq 0)
    {
        $problems.Add('No usable Proxmox node was found.')
    }

    $required = [Math]::Min($MinimumTemplateCount, $TemplateCount)
    if ($TemplateName)
    {
        $required = @($TemplateName).Count
    }

    $templates = @()
    $selected = @()
    if ($nodes)
    {
        $listed = $false
        try
        {
            $templates = @(Get-LWProxmoxVM -IncludeTemplates -NoCache | Where-Object { $_.template -eq 1 } | ConvertTo-ProxmoxLiveTestTemplateInfo)
            $listed = $true
        }
        catch
        {
            $problems.Add("Could not list the VMs and templates: $($_.Exception.Message)")
        }

        if ($listed)
        {
            $selectionFailed = $false
            $selectParameters = @{ TemplateInfo = $templates; Count = $TemplateCount }
            if ($TemplateName)
            {
                $selectParameters.Name = $TemplateName
            }

            try
            {
                $selected = @(Select-ProxmoxLiveTestTemplate @selectParameters)
            }
            catch
            {
                $selectionFailed = $true
                $problems.Add($_.Exception.Message)
            }

            if (-not $selectionFailed -and $selected.Count -lt $required)
            {
                $message = "Found $($selected.Count) usable template(s)"
                if ($selected)
                {
                    $message += " ($(($selected.Name | Sort-Object) -join ', '))"
                }
                $message += "; at least $required are required. Usable are templates for Windows 10, Windows 11 and Windows Server 2019, 2022 and 2025, tagged 'template' plus the operating system (for example windowsserver2025datacenterdesktopexperience)."

                $ignored = @($templates | Where-Object { -not $_.IsSupported })
                if ($ignored)
                {
                    $message += ' Ignored: ' + (($ignored | ForEach-Object { "$($_.Name) ($($_.Reason))" }) -join '; ') + '.'
                }

                $problems.Add($message)
            }
        }
    }

    $capabilities = @{
        OutageHandling = (Test-ProxmoxLiveTestCapability -Command 'Start-LWProxmoxAgentExecutionOnVM' -Parameter 'StatusFailureToleranceSeconds')
    }

    $leftovers = @()
    if ($nodes)
    {
        try
        {
            $leftovers = @(Get-ProxmoxLiveTestLeftoverVm | ForEach-Object { [string]$_.name })
        }
        catch
        {
            Write-Verbose "Could not look for leftover live-test VMs: $($_.Exception.Message)"
        }
    }

    [pscustomobject]@{
        HostName             = $Connection.HostName
        Port                 = $Connection.Port
        AuthType             = $Connection.AuthType
        Principal            = $Connection.Principal
        ProxmoxVersion       = $proxmoxVersion
        Nodes                = $nodes
        Templates            = $templates
        Selected             = $selected
        TemplateCount        = $TemplateCount
        MinimumTemplateCount = $required
        Capabilities         = $capabilities
        Leftovers            = $leftovers
        Problems             = $problems.ToArray()
        Ready                = $problems.Count -eq 0
    }
}

function Format-ProxmoxLiveTestPlan
{
    <#
    .SYNOPSIS
        Turns a plan into lines for the console.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory)]
        [object]$Plan
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("Proxmox host:    $($Plan.HostName):$($Plan.Port) ($($Plan.AuthType), $($Plan.Principal))")
    if ($Plan.ProxmoxVersion)
    {
        $lines.Add("Proxmox version: $($Plan.ProxmoxVersion)")
    }
    $lines.Add("Nodes:           $(@($Plan.Nodes) -join ', ')")

    $usable = @($Plan.Templates | Where-Object { $_.IsSupported }).Count
    $lines.Add("Templates found: $(@($Plan.Templates).Count), usable: $usable")

    $lines.Add('Templates used:')
    foreach ($template in @($Plan.Selected))
    {
        $release = "Windows $($template.Release)"
        if ($template.Family -eq 'Server')
        {
            $release = "Windows Server $($template.Release)"
        }
        $lines.Add(('  {0} (VMID {1}, node {2}): {3} [{4}]' -f $template.Name, $template.VmId, $template.Node, $release, $template.Selection))
    }

    if ($Plan.Capabilities.OutageHandling)
    {
        $lines.Add('Outage tests:    enabled')
    }
    else
    {
        $lines.Add('Outage tests:    skipped (the loaded AutomatedLabWorker has no -StatusFailureToleranceSeconds; build and install the current source to run them)')
    }

    if (@($Plan.Leftovers).Count -gt 0)
    {
        $lines.Add("Leftover VMs:    $(@($Plan.Leftovers).Count) live-test VM(s) from earlier runs exist ($(@($Plan.Leftovers) -join ', ')). Remove them with -RemoveLeftovers.")
    }

    if ($Plan.Ready)
    {
        $lines.Add('Ready: yes')
    }
    else
    {
        $lines.Add('Ready: no')
        foreach ($problem in @($Plan.Problems))
        {
            $lines.Add("  - $problem")
        }
    }

    $lines.ToArray()
}

function Invoke-ProxmoxLiveTestRun
{
    <#
    .SYNOPSIS
        Runs the live Proxmox tests, checks only the preflight, or removes leftover live-test VMs.

    .DESCRIPTION
        Order of work: validate the local input, collect the connection data (prompting for what is missing),
        check the prerequisites, import the modules, connect, then either remove leftovers or build the plan
        (nodes, templates, capabilities). Only a ready plan starts Pester. The VMs a run created are removed
        afterwards, also when the tests fail, unless -KeepVm is given. Nothing secret is handed to the tests.

    .PARAMETER TestRoot
        The folder that holds the *.Tests.ps1 live suites.

    .PARAMETER HostName
        Host name or IPv4 address of a Proxmox node.

    .PARAMETER Port
        API port. Defaults to 8006.

    .PARAMETER Credential
        User (for example root@pam) and password. Alternative to -ApiToken.

    .PARAMETER ApiToken
        API token USER@REALM!TOKENID=UUID as a SecureString. Alternative to -Credential.

    .PARAMETER ModulePath
        A folder with built AutomatedLab modules (for example publish). It is put in front of the module path
        for this run only.

    .PARAMETER Suite
        Run only these suites (the file names without .Tests.ps1). Defaults to all.

    .PARAMETER Template
        Use exactly these templates (VM names) instead of the automatic choice.

    .PARAMETER TemplateCount
        How many templates the tests run on. Defaults to 2.

    .PARAMETER MinimumTemplateCount
        How many usable templates must exist. Defaults to 2.

    .PARAMETER PreflightOnly
        Connect and check, print the plan, create nothing.

    .PARAMETER RemoveLeftovers
        Remove live-test VMs of earlier runs (name allive-<run>-<n> and the tag al-live-test), then stop.

    .PARAMETER SkipOutageTests
        Skip the tests that restart the guest agent inside a clone.

    .PARAMETER FullClone
        Make full clones instead of linked clones.

    .PARAMETER Storage
        Target storage for the clones. Implies full clones.

    .PARAMETER KeepVm
        Do not remove the VMs after the run.

    .PARAMETER NonInteractive
        Fail instead of prompting for missing connection data.

    .PARAMETER TestResultPath
        Write an NUnit result file to this path.

    .PARAMETER TestRunner
        The script block that starts Pester. It receives the Pester configuration. Meant for unit tests.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory)]
        [string]$TestRoot,

        [Parameter()]
        [string]$HostName,

        [Parameter()]
        [ValidateRange(1, 65535)]
        [int]$Port = 8006,

        [Parameter()]
        [pscredential]$Credential,

        [Parameter()]
        [securestring]$ApiToken,

        [Parameter()]
        [string]$ModulePath,

        [Parameter()]
        [string[]]$Suite,

        [Parameter()]
        [string[]]$Template,

        [Parameter()]
        [ValidateRange(1, 6)]
        [int]$TemplateCount = 2,

        [Parameter()]
        [ValidateRange(1, 6)]
        [int]$MinimumTemplateCount = 2,

        [Parameter()]
        [switch]$PreflightOnly,

        [Parameter()]
        [switch]$RemoveLeftovers,

        [Parameter()]
        [switch]$SkipOutageTests,

        [Parameter()]
        [switch]$FullClone,

        [Parameter()]
        [string]$Storage,

        [Parameter()]
        [switch]$KeepVm,

        [Parameter()]
        [switch]$NonInteractive,

        [Parameter()]
        [string]$TestResultPath,

        [Parameter()]
        [scriptblock]$TestRunner = { param ($Configuration) Invoke-Pester -Configuration $Configuration }
    )

    $say = {
        param ($text)

        Write-Information -MessageData $text -InformationAction Continue
    }

    # Local input is checked first, so a typo is found before anything asks for a password.
    if (-not (Test-Path -LiteralPath $TestRoot -PathType Container))
    {
        throw "Test folder '$TestRoot' not found."
    }

    $suiteFiles = @(Get-ChildItem -LiteralPath $TestRoot -Filter '*.Tests.ps1' -File | Sort-Object -Property Name)
    if (-not $suiteFiles)
    {
        throw "No *.Tests.ps1 suites found in '$TestRoot'."
    }

    if ($Suite)
    {
        $availableSuites = @($suiteFiles | ForEach-Object { $_.Name -replace '\.Tests\.ps1$', '' })
        $requestedFiles = foreach ($requested in $Suite)
        {
            $file = $suiteFiles | Where-Object { ($_.Name -replace '\.Tests\.ps1$', '') -eq $requested } | Select-Object -First 1
            if (-not $file)
            {
                throw "Unknown suite '$requested'. Available: $(($availableSuites | Sort-Object) -join ', ')."
            }

            $file
        }
        $suiteFiles = @($requestedFiles)
    }

    if ($ModulePath -and -not (Test-Path -LiteralPath $ModulePath -PathType Container))
    {
        throw "The folder given with -ModulePath was not found: '$ModulePath'."
    }

    $connectionParameters = @{ Port = $Port }
    if ($HostName)
    {
        $connectionParameters.HostName = $HostName
    }
    if ($Credential)
    {
        $connectionParameters.Credential = $Credential
    }
    if ($ApiToken)
    {
        $connectionParameters.ApiToken = $ApiToken
    }
    if ($NonInteractive)
    {
        $connectionParameters.NonInteractive = $true
    }
    $connection = Resolve-ProxmoxLiveTestConnection @connectionParameters

    $originalModulePath = $env:PSModulePath
    try
    {
        if ($ModulePath)
        {
            $resolvedModulePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ModulePath)
            $env:PSModulePath = '{0}{1}{2}' -f $resolvedModulePath, [System.IO.Path]::PathSeparator, $env:PSModulePath
        }

        $prerequisites = @(Test-ProxmoxLiveTestPrerequisite)
        $missing = @($prerequisites | Where-Object { -not $_.Ok })
        if ($missing)
        {
            $details = ($missing | ForEach-Object { "$($_.Name): $($_.Detail)" }) -join ' '
            throw "Prerequisites are missing. $details"
        }
        & $say "Prerequisites: all $($prerequisites.Count) found."

        Import-ProxmoxLiveTestModule
        Connect-ProxmoxLiveTestCluster -Connection $connection

        if ($RemoveLeftovers)
        {
            $found = @(Get-ProxmoxLiveTestLeftoverVm)
            $outcomes = @()
            if ($found)
            {
                $names = ($found | ForEach-Object { $_.name }) -join ', '
                if ($PSCmdlet.ShouldProcess("$($found.Count) live-test VM(s): $names", 'Remove'))
                {
                    foreach ($vm in $found)
                    {
                        $outcomes += Remove-ProxmoxLiveTestVm -Vm $vm -Confirm:$false
                    }
                }
            }
            else
            {
                & $say 'No leftover live-test VMs found.'
            }

            return [pscustomobject]@{
                Mode    = 'RemoveLeftovers'
                Found   = $found
                Removed = $outcomes
            }
        }

        $planParameters = @{
            Connection           = $connection
            TemplateCount        = $TemplateCount
            MinimumTemplateCount = $MinimumTemplateCount
        }
        if ($Template)
        {
            $planParameters.TemplateName = $Template
        }
        $plan = Get-ProxmoxLiveTestPlan @planParameters

        foreach ($line in (Format-ProxmoxLiveTestPlan -Plan $plan))
        {
            & $say $line
        }

        if ($PreflightOnly)
        {
            return [pscustomobject]@{
                Mode  = 'Preflight'
                Ready = $plan.Ready
                Plan  = $plan
            }
        }

        if (-not $plan.Ready)
        {
            Write-Warning 'The run did not start because the preflight found problems (see above).'
            return [pscustomobject]@{
                Mode         = 'Run'
                Ready        = $false
                Plan         = $plan
                RunId        = $null
                PesterResult = $null
                Passed       = $false
                Removed      = @()
                Kept         = @()
            }
        }

        $runId = New-ProxmoxLiveTestRunId
        $templates = @()
        $index = 0
        foreach ($selected in @($plan.Selected))
        {
            $index++
            $templates += @{
                Name    = $selected.Name
                VmId    = $selected.VmId
                Node    = $selected.Node
                Family  = $selected.Family
                Release = $selected.Release
                OsTag   = $selected.OsTag
                VmName  = New-ProxmoxLiveTestVmName -RunId $runId -Index $index
            }
        }

        # Nothing secret goes in here: the connection is already made and lives in the module.
        $liveTest = @{
            Ready        = $true
            RunId        = $runId
            Connection   = @{
                HostName  = $connection.HostName
                Port      = $connection.Port
                AuthType  = $connection.AuthType
                Principal = $connection.Principal
            }
            Templates    = $templates
            Options      = @{
                FullClone       = [bool]$FullClone
                Storage         = $Storage
                KeepVm          = [bool]$KeepVm
                SkipOutageTests = [bool]$SkipOutageTests
            }
            Capabilities = $plan.Capabilities
        }

        $containers = @(foreach ($file in $suiteFiles)
            {
                New-PesterContainer -Path $file.FullName -Data @{ LiveTest = $liveTest }
            })

        $configuration = New-PesterConfiguration
        $configuration.Run.Container = $containers
        $configuration.Run.PassThru = $true
        $configuration.Output.Verbosity = 'Detailed'
        if ($SkipOutageTests)
        {
            $configuration.Filter.ExcludeTag = @('Outage')
        }
        if ($TestResultPath)
        {
            $configuration.TestResult.Enabled = $true
            $configuration.TestResult.OutputFormat = 'NUnitXml'
            $configuration.TestResult.OutputPath = $TestResultPath
        }

        & $say "Starting run $runId with $(@($containers).Count) suite(s)."

        $pesterResult = $null
        $removed = @()
        $kept = @()
        try
        {
            $pesterResult = & $TestRunner $configuration
        }
        finally
        {
            # The run created these VMs, so its id is proof enough; this also catches a clone that never got its tag.
            $created = @()
            try
            {
                $created = @(Get-ProxmoxLiveTestLeftoverVm -RunId $runId)
            }
            catch
            {
                Write-Warning "Could not look for the VMs of run $runId : $($_.Exception.Message) Remove them later with -RemoveLeftovers."
            }

            if ($KeepVm)
            {
                $kept = $created
                foreach ($vm in $created)
                {
                    & $say "Kept live-test VM '$($vm.name)' (VMID $($vm.vmid)) on node '$($vm.node)'."
                }
            }
            else
            {
                foreach ($vm in $created)
                {
                    try
                    {
                        $removed += Remove-ProxmoxLiveTestVm -Vm $vm -Confirm:$false
                    }
                    catch
                    {
                        Write-Warning "Could not remove the live-test VM '$($vm.name)' (VMID $($vm.vmid)): $($_.Exception.Message). Remove it later with -RemoveLeftovers."
                    }
                }
            }
        }

        [pscustomobject]@{
            Mode         = 'Run'
            Ready        = $true
            RunId        = $runId
            Plan         = $plan
            PesterResult = $pesterResult
            Passed       = [bool]$pesterResult -and $pesterResult.Result -eq 'Passed'
            Removed      = $removed
            Kept         = $kept
        }
    }
    finally
    {
        $env:PSModulePath = $originalModulePath
    }
}
