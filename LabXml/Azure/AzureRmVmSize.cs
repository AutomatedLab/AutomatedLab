using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureRmVmSize : CopiedObject<AzureRmVmSize>
    {
        public int NumberOfCores { get; set; }

        public int MemoryInMB { get; set; }

        public string Name { get; set; }

        public int? MaxDataDiskCount { get; set; }

        public int ResourceDiskSizeInMB { get; set; }

        public int OSDiskSizeInMB { get; set; }

        public AzureRmVmSize()
        { }

        public static AzureRmVmSize Create(object input)
        {
            return Create<AzureRmVmSize>(input);
        }

        public static IEnumerable<AzureRmVmSize> Create(object[] input)
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create<AzureRmVmSize>(item);
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