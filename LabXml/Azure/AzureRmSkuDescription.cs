using System;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureRmSkuDescription : CopiedObject<AzureRmSkuDescription>
    {
        public int? Capacity { get; set; }
        public string Family { get; set; }
        public string Name { get; set; }
        public string Size { get; set; }
        public string Tier { get; set; }
        public AzureRmSkuDescription()
        { }

        public override string ToString()
        {
            return Name;
        }
    }
}
