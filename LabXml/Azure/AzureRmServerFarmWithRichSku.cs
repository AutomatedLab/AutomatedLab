using System;

namespace AutomatedLab.Azure
{
    public enum StatusOptions
    {
        Ready,
        Pending
    }

    [Serializable]
    public class AzureRmServerFarmWithRichSku : CopiedObject<AzureRmServerFarmWithRichSku>
    {
        public string AdminSiteName { get; set; }
        public string GeoRegion { get; set; }
        //skipping for now
        //HostingEnvironmentProfile Property   Microsoft.Azure.Management.WebSites.Models.HostingEnvironmentProfile HostingEnvironmentProfile
        public string Id { get; set; }
        public string Location { get; set; }
        public int? MaximumNumberOfWorkers { get; set; }
        public string Name { get; set; }
        public int? NumberOfSites { get; set; }
        public bool? PerSiteScaling { get; set; }
        public string ResourceGroup { get; set; }
        public string ServerFarmWithRichSkuName { get; set; }

        public AzureRmSkuDescription AzureRmSkuDescription { get; set; }
        public StatusOptions? Status { get; set; }
        public string Subscription { get; set; }
        public SerializableDictionary<string, string> Tags { get; set; }
        public string Type { get; set; }
        public string WorkerTierName { get; set; }
        //non-standard properties
        [CustomProperty]
        public string WorkerSize { get; set; }
        [CustomProperty]
        public string Tier { get; set; }
        [CustomProperty]
        public int NumberofWorkers { get; set; }

        public AzureRmServerFarmWithRichSku()
        { }

        public override string ToString()
        {
            return Name;
        }
    }
}