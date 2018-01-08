using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureRmResourceGroup : CopiedObject<AzureRmResourceGroup>
    {
        public string Location { get; set; }
        public string ResourceGroupName { get; set; }
        public string ProvisioningState { get; set; }
        public string ResourceId { get; set; }
        public string TagsTable { get; set; }
        public SerializableDictionary<string,string> Tags { get; set; }

        public AzureRmResourceGroup()
        { }

        public static AzureRmResourceGroup Create(object input)
        {
            return Create<AzureRmResourceGroup>(input);
        }

        public static IEnumerable<AzureRmResourceGroup> Create(object[] input)
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create<AzureRmResourceGroup>(item);
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
