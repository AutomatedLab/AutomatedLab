using System;
using System.Collections;
using System.Linq;
using System.Net;

namespace AutomatedLab
{
    [Serializable]
    public class AzureSubnet
    {
        private string name;
        private IPNetwork addressSpace;

        public string Name
        {
            get { return name; }
            set { name = value; }
        }

        public IPNetwork AddressSpace
        {
            get { return addressSpace; }
            set { addressSpace = value; }
        }
                
        public override string ToString()
        {
            return name;
        }

        public static implicit operator AzureSubnet(Hashtable ht)
        {
            if (ht.Keys.OfType<string>().Where(k => k == "SubnetName" | k == "SubnetAddressPrefix").Count() != 2)
            {
                return null;
            }

            var subnet = new AzureSubnet();
            subnet.name = ht["SubnetName"].ToString();

            subnet.addressSpace = ht["SubnetAddressPrefix"].ToString();

            return subnet;
        }
    }
}
