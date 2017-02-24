using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    public class AzureRmStorageAccount : CopiedObject<AzureRmStorageAccount>
    {
        public string Location { get; set; }
        public string StorageAccountName { get; set; }

        public DateTime? CreationTime { get; set; }
        public string Id { get; set; }
        public DateTime? LastGeoFailoverTime { get; set; }
        public string PrimaryLocation { get; set; }
        public string ResourceGroupName { get; set; }
        public string SecondaryLocation { get; set; }
        public string ProvisioningState { get; set; }
        public SerializableDictionary<string, string> Tags { get; set; }
        public string StatusOfPrimary { get; set; }
        public string StatusOfSecondary { get; set; }
        public string StorageAccountKey { get; set; }

        public AzureRmStorageAccount()
        { }

        public static AzureRmStorageAccount Create(object input)
        {
            return Create<AzureRmStorageAccount>(input);
        }

        public static IEnumerable<AzureRmStorageAccount> Create(object[] input)
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create<AzureRmStorageAccount>(item);
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
