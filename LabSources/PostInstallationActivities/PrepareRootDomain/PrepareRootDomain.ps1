Import-Module -Name ActiveDirectory

if (-not (Get-Command -Name Get-ADReplicationSite -ErrorAction SilentlyContinue))
{
    Write-ScreenInfo 'The script "PrepareRootDomain.ps1" script runs only if the ADReplication cmdlets are available' -Type Warning
    return
}

$password = "Password1"
$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force

#Create standard accounts
$workOu = New-ADOrganizationalUnit -Name Work -PassThru -ProtectedFromAccidentalDeletion:$false

$dev = New-ADUser -Name Dev -AccountPassword $securePassword -Path $workOu -Enabled $true -PassThru
$devAdmin = New-ADUser -Name DevAdmin -AccountPassword $securePassword -Path $workOu -Enabled $true -PassThru
Get-ADGroup -Identity Administrators | Add-ADGroupMember -Members $devAdmin -PassThru
Get-ADGroup -Identity 'Domain Admins' | Add-ADGroupMember -Members $devAdmin -PassThru
Get-ADGroup -Identity 'Enterprise Admins' | Add-ADGroupMember -Members $devAdmin -PassThru

#Create replication sites, subnets and site links
$sites = Import-Csv $PSScriptRoot\Sites.txt -Delimiter ';'
Write-Verbose "Imported $($sites.Count) sites"
$subnets = Import-Csv $PSScriptRoot\Subnets.txt -Delimiter ';'
Write-Verbose "Imported $($subnets.Count) subnets"

$sites | New-ADReplicationSite -PassThru
Write-Verbose "Sites created"
$subnets | New-ADReplicationSubnet -PassThru
Write-Verbose "Subnets created"

Write-Verbose "Creating one site link for each branch site"
Write-Verbose "`tHub Site is 'Munich'"
$hubSite = Get-ADReplicationSite -Identity Munich
$branchSites = Get-ADReplicationSite -Filter * | Where-Object { $_.Name -ne $hubSite.Name }

foreach ($branchSite in $branchSites)
{
    Write-Verbose ("Creating Link from '{0}' to '{1}'" -f $hubSite.Name, $branchSite.Name)
    New-ADReplicationSiteLink -Name "$($hubSite.Name) - $($branchSite.Name)" `
        -SitesIncluded $hubSite, $branchSite `
        -Description "Standard Site Link" -OtherAttributes @{'options' = 1 } `
        -Cost 100 -ReplicationFrequencyInMinutes 15 `
        -PassThru
}

$repAllScript = @'
REPADMIN /viewlist * > DCs.txt

:: FOR /F "tokens=3" %%a IN (DCs.txt) DO ECHO dadasdads %%a
FOR /F "tokens=3" %%a IN (DCs.txt) DO CALL REPADMIN /SyncAll /AeP %%a

DEL DCs.txt

REPADMIN /ReplSum
'@

$repAllScript | Out-File -FilePath C:\Windows\RepAll.bat

RepAll.bat