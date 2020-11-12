using namespace Microsoft.PowerShell.SHiPS

[SHiPSProvider(UseCache = $true)]
[SHiPSProvider(BuiltinProgress = $false)]
class LabHost : SHiPSDirectory {
    LabHost(
        [string]$name) : base($name) {
    }

    [object[]] GetChildItem() {
        if (-not (Get-Module -ListAvailable (AutomatedLab)))
        {
            Write-Warning -Message 'AutomatedLab is not available - using its SHiPS provider will not work this way'
            return $null
        }
        $labs = @()
        foreach ($lab in (Get-Lab -List)) {
            $labs += [Lab]::new($lab)
        }
        return $labs
    }
}

[SHiPSProvider(UseCache = $true)]
[SHiPSProvider(BuiltinProgress = $false)]
class Lab : SHiPSDirectory {
    Lab(
        [string]$name) : base($name) {
    }

    [object[]] GetChildItem() {
        Import-Lab -Name $this.name -NoValidation
        $obj = @()

        $obj += [LabMachine]::new('Machines')
        $obj += [LabDisk]::new('Disks')
        $obj += [LabNetwork]::new('Networks')
        $obj += [LabDomain]::new('Domains')

        return $obj;
    }
}

[SHiPSProvider(UseCache = $true)]
[SHiPSProvider(BuiltinProgress = $false)]
class LabMachine : SHiPSDirectory {
    LabMachine([string]$name) : base($name) {

    }

    [object[]] GetChildItem() {
        return (Get-LabVm)
    }
}

[SHiPSProvider(UseCache = $true)]
[SHiPSProvider(BuiltinProgress = $false)]
class LabNetwork : SHiPSDirectory {
    LabNetwork([string]$name) : base($name) {

    }

    [object[]] GetChildItem() {
        return (Get-Lab).VirtualNetworks
    }
}

[SHiPSProvider(UseCache = $true)]
[SHiPSProvider(BuiltinProgress = $false)]
class LabDisk : SHiPSDirectory {
    LabDisk([string]$name) : base($name) {

    }

    [object[]] GetChildItem() {
        return (Get-Lab).Disks
    }
}

[SHiPSProvider(UseCache = $true)]
[SHiPSProvider(BuiltinProgress = $false)]
class LabDomain : SHiPSDirectory {
    LabDomain([string]$name) : base($name) {

    }

    [object[]] GetChildItem() {
        return (Get-Lab).Domains
    }
}
