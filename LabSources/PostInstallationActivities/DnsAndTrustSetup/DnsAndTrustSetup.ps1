#region Internals
#region Get-Type (helper function for creating generic types)
function Get-Type
{
	param(
    	[Parameter(Position=0,Mandatory=$true)]
		[string] $GenericType,

		[Parameter(Position=1,Mandatory=$true)]
		[string[]] $T
    )

	$T = $T -as [type[]]

	try
	{
		$generic = [type]($GenericType + '`' + $T.Count)
		$generic.MakeGenericType($T)
	}
	catch [Exception]
	{
		throw New-Object System.Exception("Cannot create generic type", $_.Exception)
	}
}
#endregion

#region Item Type
$type = @"
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Mesh
{
    public class Item<T> where T : class
    {
        private T source;
        private T destination;

        public T Source
        {
            get { return source; }
            set { source = value; }
        }

        public T Destination
        {
            get { return destination; }
            set { destination = value; }
        }

        public override string ToString()
        {
            return string.Format("{0} - {1}", source.ToString(), destination.ToString());
        }

        public override int GetHashCode()
        {
            return source.GetHashCode() ^ destination.GetHashCode();
        }

        public override bool Equals(object obj)
        {
            T otherSource = null;
            T otherDestination = null;

            if (obj == null)
                return false;

            if (obj.GetType().IsArray)
            {
                var array = (object[])obj;
                if (typeof(T) != array[0].GetType() || typeof(T) != array[1].GetType())
                    return false;
                else
                {
                    otherSource = (T)array[0];
                    otherDestination = (T)array[1];
                }

                if (!otherSource.Equals(this.source))
                    return false;

                return otherDestination.Equals(this.destination);
            }
            else
            {
                if (GetType() != obj.GetType())
                    return false;

                Item<T> otherObject = (Item<T>)obj;

                if (!this.destination.Equals(otherObject.destination))
                    return false;

                return this.source.Equals(otherObject.source);
            }
        }
    }
}
"@
#endregion Item Type
#endregion Internals

function Get-Mesh
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [array]$List,

        [switch]$OneWay
    )

    $mesh = New-Object System.Collections.ArrayList

    foreach ($item1 in $List)
    {
        foreach ($item2 in $list)
        {
            if ($item1 -eq $item2)
            { continue }

            if ($mesh.Contains(($item1, $item2)))
            { continue }

            if ($OneWay)
            {
                if ($mesh.Contains((New-Object (Get-Type -GenericType Mesh.Item -T string) -Property @{ Source = $item2; Destination = $item1 })))
                { continue }
            }

            $mesh.Add((New-Object (Get-Type -GenericType Mesh.Item -T string) -Property @{ Source = $item1; Destination = $item2 } )) | Out-Null
        }
    }

    $mesh
}

Add-Type -TypeDefinition $type

$forestNames = (Get-LabVM -Role RootDC).DomainName
if (-not $forestNames)
{
    Write-Error 'Could not get forest names from the lab'
    return
}

$forwarders = Get-Mesh -List $forestNames

foreach ($forwarder in $forwarders)
{
    $targetMachine = Get-LabVM -Role RootDC | Where-Object { $_.DomainName -eq $forwarder.Source }
    $masterServers = Get-LabVM -Role DC,RootDC,FirstChildDC | Where-Object { $_.DomainName -eq $forwarder.Destination }

    $cmd = @"
        `$VerbosePreference = 'Continue'
        Write-Verbose "Creating a DNS forwarder on server '$(hostname)'. Forwarder name is '$($forwarder.Destination)' and target DNS server is '$($masterServers.IpV4Address)'..."
        #Add-DnsServerConditionalForwarderZone -ReplicationScope Forest -Name $($forwarder.Destination) -MasterServers $($masterServers.IpV4Address)
        dnscmd . /zoneadd $($forwarder.Destination) /forwarder $($masterServers.IpV4Address)
        Write-Verbose '...done'
"@

    Invoke-LabCommand -ComputerName $targetMachine -ScriptBlock ([scriptblock]::Create($cmd))
}

$rootDcs = Get-LabVM -Role RootDC
$syncJobs = foreach ($rootDc in $rootDcs)
{
	Sync-LabActiveDirectory -ComputerName $rootDc -AsJob
}
Wait-LWLabJob -Job $syncJobs

$trustMesh = Get-Mesh -List $forestNames -OneWay

foreach ($rootDc in $rootDcs)
{
    $trusts = $trustMesh | Where-Object { $_.Source -eq $rootDc.DomainName }

    Write-Verbose "Creating trusts on machine $($rootDc.Name)"
    foreach ($trust in $trusts)
    {
        $domainAdministrator = ((Get-Lab).Domains | Where-Object { $_.Name -eq ($rootDcs | Where-Object { $_.DomainName -eq $trust.Destination }).DomainName }).Administrator

        $cmd = @"
            `$thisForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()

            `$otherForestCtx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext(
                [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Forest,
                '$($trust.Destination)',
                '$($domainAdministrator.UserName)',
                '$($domainAdministrator.Password)')
            `$otherForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest(`$otherForestCtx)

            Write-Verbose "Creating forest trust between forests '`$(`$thisForest.Name)' and '`$(`$otherForest.Name)'"

            `$thisForest.CreateTrustRelationship(
                `$otherForest,
                [System.DirectoryServices.ActiveDirectory.TrustDirection]::Bidirectional
            )

            Write-Verbose 'Forest trust created'
"@

        Invoke-LabCommand -ComputerName $rootDc -ScriptBlock ([scriptblock]::Create($cmd))
    }
}