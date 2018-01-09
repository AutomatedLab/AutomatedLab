using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureRmService : CopiedObject<AzureRmService>
    {
        public int? AvailabilityState { get; set; } //System.Nullable[Microsoft.Azure.Management.WebSites.Models.SiteAvailabilityState]
        public bool? ClientAffinityEnabled { get; set; }
        public bool? ClientCertEnabled { get; set; }
        //ignoring this for now
        //CloningInfo Property   Microsoft.Azure.Management.WebSites.Models.CloningInfo CloningInfo { get; set; }
        public int? ContainerSize { get; set; }
        public string DefaultHostName { get; set; }
        public bool? Enabled { get; set; }
        public List<string> EnabledHostNames { get; set; }
        public string GatewaySiteName { get; set; }
        //ignoring this for now
        //HostingEnvironmentProfile Property   Microsoft.Azure.Management.WebSites.Models.HostingEnvironmentProfile HostingEnvironmentProfile { get; set; }
        public List<string> HostNames { get; set; }
        public bool? HostNamesDisabled { get; set; }
        public List<AzureRmHostNameSslState> HostNameSslStates { get; set; } //System.Collections.Generic.IList[Microsoft.Azure.Management.WebSites.Models.HostNameSslState]
        public string Id { get; set; }
        public bool? IsDefaultContainer { get; set; }
        public DateTime? LastModifiedTimeUtc { get; set; }
        public string Location { get; set; }
        public int? MaxNumberOfWorkers { get; set; }
        public string MicroService { get; set; }
        public string Name { get; set; }
        public string OutboundIpAddresses { get; set; }
        public bool? PremiumAppDeployed { get; set; }
        public string RepositorySiteName { get; set; }
        public string ResourceGroup { get; set; }
        public bool? ScmSiteAlsoStopped { get; set; }
        public string ServerFarmId { get; set; }
        //ignoring this for now
        //SiteConfig Property   Microsoft.Azure.Management.WebSites.Models.SiteConfig SiteConfig { get; set; }
        public string SiteName { get; set; }
        public string State { get; set; }
        public SerializableDictionary<string, string> Tage { get; set; }
        public string TargetSwapSlot { get; set; }
        public SerializableList<string> TrafficManagerHostNames { get; set; }
        public string Type { get; set; }
        public int? UsageState { get; set; }
        //non-standard properties
        public string ApplicationServicePlan { get; set; }

        public AzureRmService()
        { }

        public override string ToString()
        {
            return Name;
        }
    }
}