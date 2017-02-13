using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AutomatedLab.Azure
{
    public class AzureAvailabilitySet
    {
        public int Id { get; set; }

        public string Location { get; set; }
        public string Name { get; set; }
        public int? PlatformFaultDomainCount { get; set; }
        public int? PlatformUpdateDomainCount { get; set; }
        public string ResourceGroupName { get; set; }
    }
}
