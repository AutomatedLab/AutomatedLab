using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureRoleSize : CopiedObject<AzureRoleSize>
    {
        public string InstanceSize { get; set; }

        public int Cores { get; set; }

        public int MemoryInMb { get; set; }

        public string RoleSizeLabel { get; set; }

        public int? MaxDataDiskCount { get; set; }

        public int? VirtualMachineResourceDiskSizeInMb { get; set; }

        public AzureRoleSize()
        { }

        public static AzureRoleSize Create(object input)
        {
            return Create<AzureRoleSize>(input);
        }

        public static IEnumerable<AzureRoleSize> Create(object[] input)
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create<AzureRoleSize>(item);
                }
            }
            else
            {
                yield break;
            }
        }

        public override string ToString()
        {
            return InstanceSize;
        }
    }    
}