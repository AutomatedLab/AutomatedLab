using System;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureSubscription : CopiedObject<AzureSubscription>
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string State { get; set; }
        public string TenantId { get; set; }
        public string SubscriptionId { get; set; }
        public SerializableDictionary<string, string> Tags { get; set; }
        public string CurrentStorageAccountName { get; set; }
        public SerializableDictionary<string,string> ExtendedProperties { get; set; }


        public AzureSubscription()
        { }

        public override string ToString()
        {
            return Name;
        }
    }
}
