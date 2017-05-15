using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureSubscription : CopiedObject<AzureSubscription>
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string State { get; set; }
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
            return Name;
        }
    }
}
