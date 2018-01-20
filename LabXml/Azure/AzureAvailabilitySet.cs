using System;

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

        public override string ToString()
        {
            return Name;
        }
    }
}
