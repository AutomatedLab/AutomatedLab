using System;

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
        public SerializableDictionary<string, string> Tags { get; set; }

        public AzureRmResourceGroup()
        { }

        public override string ToString()
        {
            return ResourceGroupName;
        }
    }
}
