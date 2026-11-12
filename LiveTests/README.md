# Live tests

Integration tests that run against a real infrastructure host. They are
opt-in: the build runs everything under `Tests\` and never looks here, and
every suite skips itself unless the runner hands it live-test data. A stray
`Invoke-Pester .` therefore cannot touch a host.

The logic of the runner (input handling, template selection, plan, cleanup) is
unit-tested in `Tests\Unit\LiveTests`, which the normal build does run.

## Proxmox

The entry point is `Proxmox\Invoke-ProxmoxLiveTest.ps1`. Start it in a new
PowerShell session, so that no older AutomatedLab module is already loaded.

```powershell
# Look first. Connects, checks, prints the plan, creates nothing.
.\Proxmox\Invoke-ProxmoxLiveTest.ps1 -HostName 192.168.1.10 -PreflightOnly

# The same, but it also names the suites and templates a run would use.
.\Proxmox\Invoke-ProxmoxLiveTest.ps1 -HostName 192.168.1.10 -WhatIf

# Run all suites with an API token and the modules of a local build.
$token = Read-Host -Prompt 'API token' -AsSecureString
.\Proxmox\Invoke-ProxmoxLiveTest.ps1 -HostName pve1.lab.local -ApiToken $token -ModulePath ..\publish

# Only the guest agent suite, without the tests that restart the agent.
.\Proxmox\Invoke-ProxmoxLiveTest.ps1 -HostName pve1 -Credential (Get-Credential root@pam) -Suite GuestAgent -SkipOutageTests

# Remove live-test VMs that an earlier, interrupted run left behind.
.\Proxmox\Invoke-ProxmoxLiveTest.ps1 -HostName pve1 -RemoveLeftovers -WhatIf
```

Run `Get-Help .\Proxmox\Invoke-ProxmoxLiveTest.ps1 -Full` for every parameter.

### What happens before a test runs

1. The input is checked: test folder, suites, module path.
2. Host, port and either a user with password or an API token are collected.
   Whatever is missing is asked for. Nothing is written to disk or printed, and
   a malformed token is rejected without being echoed. The runner keeps the
   secrets as `SecureString` or `PSCredential` objects and hands none to the
   suites. The connection that AutomatedLab makes with them
   (`Connect-LabProxmoxCluster`) is different: it holds the token as plain text,
   like the ticket of the Proxmox module, in the memory of the PowerShell
   session until the session ends, and it does not check the certificate of the
   host. Run the tests from a network you trust and close the session
   afterwards.
3. The prerequisites are checked, and nothing is installed: PowerShell 7 or
   later (the manifest of `Corsinvest.ProxmoxVE.Api` requires it), Pester 5.3 or
   later, `Corsinvest.ProxmoxVE.Api`, `PSFramework` and the AutomatedLab modules.
   Use `-ModulePath` for a build output such as `publish`.
4. The modules are imported and the connection is made and proven.
5. The host is inspected: nodes, templates, the loaded worker's capabilities and
   leftovers of earlier runs. Only a ready plan starts the tests.

### Templates

A template is a VM with the template flag and the tags `template` plus the
operating system, for example `windowsserver2025datacenterdesktopexperience`.
That is the rule AutomatedLab itself uses. Supported are Windows 10, Windows 11
and Windows Server 2019, 2022 and 2025. Not all of them are needed.

A run needs at least two usable templates and uses two. Without `-Template`
it takes the newest server and the newest client, because that pair covers both
code paths: a client image has real AppX work for the Sysprep cleanup, and the
guest agent incident that started these tests happened on Server 2025. If a host
has only servers or only clients, the two newest releases are used. A third
template adds run time (each one is a clone, a boot and a Windows first start)
rather than coverage, so more than two is opt-in through `-TemplateCount`.

### Suites

| Suite        | Creates VMs | What it checks                                  |
|--------------|-------------|--------------------------------------------------|
| `Connection` | no          | API, nodes, storage                              |
| `Templates`  | no          | tags, one template per OS tag, guest agent option |
| `GuestAgent` | yes         | waited commands, failure modes, lost result      |

The tests tagged `Outage` restart the QEMU guest agent inside a clone while a
command runs. They need an AutomatedLabWorker that knows
`-StatusFailureToleranceSeconds`; with an older one they are skipped and the plan
says so. The waited command is the guest script
`Proxmox\Guest\Restart-GuestAgentDuringCommand.ps1`: it schedules the restart of
the agent service as a SYSTEM task and keeps running, so the restart always
falls inside the command. It logs to `C:\Windows\Temp\ALLiveRestartAgent.log` in
the clone, and the test prints that log when the result was not lost.

### Safety

- A VM is only ever created or removed when its name has the form
  `allive-<8 lower-case hex characters>-<number>`. Leftover removal additionally requires
  the tag `al-live-test`. It cannot tell the VMs of an interrupted run from those
  of a run that is still going on, so use `-RemoveLeftovers` only while no other
  run is active.
- A clone is tagged, loses all its network adapters (the guest agent needs
  none, and a booted copy of a golden image cannot clash with a lab machine)
  and is removed after the run, also when the tests fail. `-KeepVm` keeps it.
- Linked clones are the default. `-FullClone` makes full clones; `-Storage`
  chooses a target storage and implies a full clone.
- The user or token needs enough rights to clone, configure, start and destroy
  VMs and to use the guest agent, for example the `PVEVMAdmin` role on `/vms`
  plus `PVEDatastoreUser` on the target storage. That role covers every VM of
  the cluster, so use a dedicated user or token for the tests and remove it when
  you no longer need it. The tests only read the selected templates and only
  create, start and remove VMs named `allive-...`.

### Not covered

- The AppX cleanup retry of `Start-LWProxmoxWindowsSysprep` and a full
  `Install-Lab` deployment: both generalize the VM. They need a lab definition
  and are a candidate for a separate suite.
- A tolerated outage after which the command still finishes (the agent
  stays alive but unreachable for a while).
- The suites were developed against a simulated Proxmox backend. Their first run
  on a real host (2026-11-11, Proxmox VE 9.2, Windows Server 2025 and Windows 11
  clones) passed all tests but three: the agent option of one template, which
  Proxmox returned as `enabled=true`, and the two outage tests, in which the
  agent was not restarted during the command. Both are fixed, and a rerun on
  the same host passed every test.

### Adding a suite

Add a `*.Tests.ps1` file to `Proxmox\`. Take the container data with
`param ([hashtable]$LiveTest)` and give every `Describe` the guard
`-Skip:(-not ($LiveTest -and $LiveTest.Ready))`. A unit test enforces both, and
it also refuses a suite that connects to Proxmox itself or asks for a secret.
`$LiveTest` carries the run id, the selected templates with their clone names
and the options; it never carries a secret.

Catch errors in `BeforeAll` and let the first test report them, as the existing
suites do. Pester 6 reports an error that escapes `BeforeAll` only as a stray
`break` or `continue` statement, which hides the real cause; errors inside a
test are reported normally. Tests that depend on the setup call
`Set-ItResult -Skipped` when it failed, so one failure is not repeated by every
test of the suite.

Scripts that run inside the guest belong in `Proxmox\Guest\`. A suite sends one
as an encoded command; keep it in Windows PowerShell 5.1 and ASCII, and unit
test the logic that needs no guest, as `Select-QemuGuestAgentService` is tested
in `Tests\Unit\LiveTests`.
