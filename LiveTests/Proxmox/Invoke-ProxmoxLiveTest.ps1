<#
.SYNOPSIS
    Runs the opt-in live tests against a Proxmox host. The normal build never calls this script.

.DESCRIPTION
    Takes the host and the credentials, checks the prerequisites and the templates on the host, and only then runs
    the suites in this folder against throwaway clones. Use -PreflightOnly to see what would happen without
    creating anything.

    Credentials are asked for when they are not passed. They are held in memory only, never written to disk and
    never printed.

    A host is ready when it has at least two supported templates: Windows 10, Windows 11, Windows Server 2019,
    2022 or 2025, each a VM with the template flag and the tags 'template' plus the operating system (for example
    windowsserver2025datacenterdesktopexperience). The default choice is the newest server and the newest client.

    Start it in a new PowerShell session so that no older AutomatedLab module is already loaded.

.PARAMETER HostName
    Host name or IPv4 address of a Proxmox node, without scheme, port or path.

.PARAMETER Port
    API port. Defaults to 8006.

.PARAMETER Credential
    User (for example root@pam) and password. Alternative to -ApiToken.

.PARAMETER ApiToken
    API token USER@REALM!TOKENID=UUID as a SecureString. Alternative to -Credential.

.PARAMETER ModulePath
    A folder with built AutomatedLab modules, for example the publish folder of a local build. It is put in front
    of the module path for this run only. Without it the installed modules are used.

.PARAMETER Suite
    Run only these suites: Connection, Templates, GuestAgent. Defaults to all.

.PARAMETER Template
    Use exactly these templates (VM names) instead of the automatic choice.

.PARAMETER TemplateCount
    How many templates the tests run on. Defaults to 2.

.PARAMETER MinimumTemplateCount
    How many usable templates must exist. Defaults to 2.

.PARAMETER PreflightOnly
    Connect and check, print the plan, create nothing.

.PARAMETER RemoveLeftovers
    Remove live-test VMs of earlier runs (name allive-<run>-<n> and tag al-live-test), then stop. Honors -WhatIf.

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

.PARAMETER PassThru
    Return the result object.

.EXAMPLE
    .\Invoke-ProxmoxLiveTest.ps1 -HostName 192.168.1.10 -PreflightOnly

    Asks for the credentials, connects, prints the templates that would be used and stops.

.EXAMPLE
    $token = Read-Host -Prompt 'API token' -AsSecureString
    .\Invoke-ProxmoxLiveTest.ps1 -HostName pve1.lab.local -ApiToken $token -ModulePath ..\..\publish

    Runs all suites with an API token and the modules of a local build.

.EXAMPLE
    .\Invoke-ProxmoxLiveTest.ps1 -HostName pve1 -Credential (Get-Credential root@pam) -Suite GuestAgent -SkipOutageTests

    Runs only the guest agent suite and leaves out the tests that restart the agent.

.EXAMPLE
    .\Invoke-ProxmoxLiveTest.ps1 -HostName pve1 -RemoveLeftovers -WhatIf

    Shows which live-test VMs of earlier runs would be removed.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
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
    [switch]$PassThru
)

. (Join-Path $PSScriptRoot 'ProxmoxLiveTest.Support.ps1')

$runParameters = @{ TestRoot = $PSScriptRoot }
$forwarded = 'HostName', 'Port', 'Credential', 'ApiToken', 'ModulePath', 'Suite', 'Template', 'TemplateCount',
'MinimumTemplateCount', 'PreflightOnly', 'RemoveLeftovers', 'SkipOutageTests', 'FullClone', 'Storage', 'KeepVm',
'NonInteractive', 'TestResultPath'
foreach ($name in $forwarded)
{
    if ($PSBoundParameters.ContainsKey($name))
    {
        $runParameters[$name] = $PSBoundParameters[$name]
    }
}

$result = Invoke-ProxmoxLiveTestRun @runParameters

$succeeded = $true
switch ($result.Mode)
{
    'Run'
    {
        $succeeded = [bool]$result.Passed
        if ($result.PesterResult)
        {
            $summary = 'Result: {0} (passed {1}, failed {2}, skipped {3}).' -f $result.PesterResult.Result, $result.PesterResult.PassedCount, $result.PesterResult.FailedCount, $result.PesterResult.SkippedCount
            Write-Information -MessageData $summary -InformationAction Continue
        }
    }
    'Preflight'
    {
        $succeeded = [bool]$result.Ready
    }
}

if ($PassThru)
{
    $result
}

if (-not $succeeded)
{
    exit 1
}
