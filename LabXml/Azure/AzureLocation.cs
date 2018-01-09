using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureLocation : CopiedObject<AzureLocation>
    {
        public string Location { get; set; }
        public string DisplayName { get; set; }
        public List<string> Providers { get; set; }

        public AzureLocation()
        { }

        public override string ToString()
        {
            return Location;
        }
    }
}
