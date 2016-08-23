using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    public class AzureStorageService : CopiedObject<AzureStorageService>
    {
        public string AccountType { get; set; }
        public string AffinityGroup { get; set; }
        public List<string> Endpoints { get; set; }
        public string GeoPrimaryLocation { get; set; }
        public bool? GeoReplicationEnabled { get; set; }
        public string GeoSecondaryLocation { get; set; }
        public string Label { get; set; }
        public string Location { get; set; }
        public string StatusOfPrimary { get; set; }
        public string StatusOfSecondary { get; set; }
        public string StorageAccountDescription { get; set; }
        public string StorageAccountName { get; set; }
        public string StorageAccountStatus { get; set; }

        public AzureStorageService()
        { }

        public static AzureStorageService Create(object input)
        {
            return Create<AzureStorageService>(input);
        }

        public static IEnumerable<AzureStorageService> Create(object[] input)
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create<AzureStorageService>(item);
                }
            }
            else
            {
                yield break;
            }
        }

        public override string ToString()
        {
            return StorageAccountName;
        }
    }
}
