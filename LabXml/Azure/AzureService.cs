using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureService : CopiedObject<AzureService>
    {
        public string AffinityGroup { get; set; }
        public DateTime DateCreated { get; set; }
        public DateTime DateModified { get; set; }
        public string Description { get; set; }
        public SerializableDictionary<string, string> ExtendedProperties { get; set; }
        public string Label { get; set; }
        public string Location { get; set; }
        public string ReverseDnsFqdn { get; set; }
        public string ServiceName { get; set; }
        public string Status { get; set; }
        public string Url { get; set; }
        public List<string> VirtualMachineRoleSizes { get; set; }
        public List<string> WebWorkerRoleSizes { get; set; }

        public AzureService()
        { }

        public static AzureService Create(object input)
        {
            return Create<AzureService>(input);
        }

        public static IEnumerable<AzureService> Create(object[] input)
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create<AzureService>(item);
                }
            }
            else
            {
                yield break;
            }
        }

        public override string ToString()
        {
            return ServiceName;
        }
    }
}
