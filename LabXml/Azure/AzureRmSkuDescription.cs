using System;
using System.Collections.Generic;

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

        public static AzureRmSkuDescription Create(object input)
        {
            return Create<AzureRmSkuDescription>(input);
        }

        public static IEnumerable<AzureRmSkuDescription> Create(object[] input)
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create<AzureRmSkuDescription>(item);
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
