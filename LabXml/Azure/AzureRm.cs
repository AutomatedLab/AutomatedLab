using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureRm
    {
        public List<AzureRmService> Services { get; set; }
        public List<AzureRmServerFarmWithRichSku> ServicePlans { get; set; }

        public AzureRm()
        {
            Services = new SerializableList<AzureRmService>();
            ServicePlans = new SerializableList<AzureRmServerFarmWithRichSku>();
        }
    }
}
