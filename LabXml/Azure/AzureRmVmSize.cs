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
        public SerializableList<string> Generation {get; set;}

        public AzureRmVmSize()
        {
            Generation = new SerializableList<string>();
        }

        public override string ToString()
        {
            return Name;
        }
    }    
}