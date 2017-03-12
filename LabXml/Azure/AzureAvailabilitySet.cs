using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureAvailabilitySet : CopiedObject<AzureAvailabilitySet>
    {
        public string Id { get; set; }

        public string Location { get; set; }
        public string Name { get; set; }
        public int? PlatformFaultDomainCount { get; set; }
        public int? PlatformUpdateDomainCount { get; set; }
        public string ResourceGroupName { get; set; }

        public AzureAvailabilitySet()
        { }

        public static AzureAvailabilitySet Create(object input)
        {
            return Create<AzureAvailabilitySet>(input);
        }

        public static IEnumerable<AzureAvailabilitySet> Create(object[] input)
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create<AzureAvailabilitySet>(item);
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
