using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureResourceGroup : CopiedObject<AzureResourceGroup>
    {
        public string Location { get; set; }
        public string ResourceGroupName { get; set; }
        public string ProvisioningState { get; set; }
        public string ResourceId { get; set; }
        public string TagsTable { get; set; }

        public AzureResourceGroup()
        { }

        public static AzureResourceGroup Create(object input)
        {
            return Create<AzureResourceGroup>(input);
        }

        public static IEnumerable<AzureResourceGroup> Create(object[] input)
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create<AzureResourceGroup>(item);
                }
            }
            else
            {
                yield break;
            }
        }

        public override string ToString()
        {
            return ResourceGroupName;
        }
    }
}
