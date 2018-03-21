using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    public enum UsageState
    {
        Normal,
        Exceeded
    }

    public enum SiteAvailabilityState
    {
        Normal,
        Limited,
        DisasterRecoveryMode
    }

    [Serializable]
    public class PublishProfile : CopiedObject<PublishProfile>
    {
        public string ControlPanelLink { get; set; }
        public string Databases { get; set; }
        public string DestinationAppUrl { get; set; }
        public string HostingProviderForumLink { get; set; }
        public string MsdeploySite { get; set; }
        public string MySQLDBConnectionString { get; set; }
        public string ProfileName { get; set; }
        public string PublishMethod { get; set; }
        public string PublishUrl { get; set; }
        public string SQLServerDBConnectionString { get; set; }
        public string UserName { get; set; }
        public string UserPWD { get; set; }
        public string WebSystem { get; set; }

        public PublishProfile()
        { }
    }

    [Serializable]
    public class AzureRmService : CopiedObject<AzureRmService>
    {
        public SiteAvailabilityState? AvailabilityState { get; set; } //System.Nullable[Microsoft.Azure.Management.WebSites.Models.SiteAvailabilityState]
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
        public SerializableDictionary<string, string> Tags { get; set; }
        public string TargetSwapSlot { get; set; }
        public List<string> TrafficManagerHostNames { get; set; }
        public string Type { get; set; }
        public UsageState? UsageState { get; set; }

        //non-standard properties
        [CustomProperty]
        public string ApplicationServicePlan { get; set; }
        [CustomProperty]
        public List<PublishProfile> PublishProfiles { get; set; }

        public AzureRmService()
        {
            PublishProfiles = new List<PublishProfile>();
        }

        public override string ToString()
        {
            return Name;
        }
    }
}