using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureLocation : CopiedObject<AzureLocation>
    {
        public string Name { get; set; }

        public string DisplayName { get; set; }

        public List<string> AvailableServices { get; set; }

        public List<string> StorageAccountTypes { get; set; }

        public List<string> VirtualMachineRoleSizes { get; set; }

        public List<string> WebWorkerRoleSizes { get; set; }

        public AzureLocation()
        { }

        public static AzureLocation Create(object input)
        {
            return Create<AzureLocation>(input);
        }

        public static IEnumerable<AzureLocation> Create(object[] input)
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create<AzureLocation>(item);
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
