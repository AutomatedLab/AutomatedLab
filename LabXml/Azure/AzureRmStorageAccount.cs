using System;

namespace AutomatedLab.Azure
{
    public enum ProvisioningState
    {
        Creating,
        ResolvingDNS,
        Succeeded
    }

    public enum AccountStatus
    {
        Available,
        Unavailable
    }

    public enum AccessTier
    {
        Hot,
        Cool
    }

    public class AzureRmStorageAccount : CopiedObject<AzureRmStorageAccount>
    {
        public string Location { get; set; }
        public string StorageAccountName { get; set; }
        public DateTime? CreationTime { get; set; }
        public string Id { get; set; }
        public string Kind { get; set; }
        public AccessTier? AccessTier { get; set; }
        public DateTime? LastGeoFailoverTime { get; set; }
        public string PrimaryLocation { get; set; }
        public string ResourceGroupName { get; set; }
        public string SecondaryLocation { get; set; }
        public ProvisioningState? ProvisioningState { get; set; }
        public SerializableDictionary<string, string> Tags { get; set; }
        public AccountStatus? StatusOfPrimary { get; set; }
        public AccountStatus? StatusOfSecondary { get; set; }
        public string StorageAccountKey { get; set; }

        public AzureRmStorageAccount()
        { }

        public override string ToString()
        {
            return StorageAccountName;
        }
    }
}
