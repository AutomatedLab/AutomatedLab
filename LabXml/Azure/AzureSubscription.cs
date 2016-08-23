using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureSubscription : CopiedObject<AzureSubscription>
    {
        public AzureAccount[] Accounts { get; set; }
        public string CurrentStorageAccountName { get; set; }
        public string DefaultAccount { get; set; }
        public string Environment { get; set; }
        public bool IsCurrent { get; set; }
        public bool IsDefault { get; set; }
        public string SubscriptionId { get; set; }
        public string SubscriptionName { get; set; }
        public string SupportedModes { get; set; }
        public string TenantId { get; set; }

        public AzureSubscription()
        { }

        public static AzureSubscription Create(object input)
        {
            return Create<AzureSubscription>(input);
        }

        public static IEnumerable<AzureSubscription> Create(object[] input)
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create<AzureSubscription>(item);
                }
            }
            else
            {
                yield break;
            }
        }

        public override string ToString()
        {
            return SubscriptionName;
        }
    }
}
