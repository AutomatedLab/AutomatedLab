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
        public bool Gen1Supported {get; set;}
        public bool Gen2Supported {get; set;}

        public AzureRmVmSize()
        {  }

        public override string ToString()
        {
            return Name;
        }
    }    
}