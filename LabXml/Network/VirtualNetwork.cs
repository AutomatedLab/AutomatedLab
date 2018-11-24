﻿using System;
using System.Collections.Generic;
using System.Net;
using System.Xml.Serialization;

namespace AutomatedLab
{
    [Serializable]
    public class VirtualNetwork
    {
        private string name;
        private IPNetwork addressSpace;
        private SwitchType switchType;
        private string adapterName;
        private string locationName;
        private VirtualizationHost hostType;
        private List<AzureSubnet> subnets = new List<AzureSubnet>();
        private List<string> connectToVnets = new List<string>();
        private List<IPAddress> dnsServers = new List<IPAddress>();
        private List<IPAddress> issuedIpAddresses = new List<IPAddress>();

        public List<AzureSubnet> Subnets
        {
            get { return subnets; }
            set { subnets = value; }
        }

        [XmlAttribute]
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

        [XmlAttribute]
        public SwitchType SwitchType
        {
            get { return switchType; }
            set { switchType = value; }
        }

        [XmlAttribute]
        public string AdapterName
        {
            get { return adapterName; }
            set { adapterName = value; }
        }

        [XmlAttribute]
        public string LocationName
        {
            get { return locationName; }
            set { locationName = value; }
        }

        [XmlAttribute]
        public VirtualizationHost HostType
        {
            get { return hostType; }
            set { hostType = value; }
        }
        public List<string> ConnectToVnets
        {
            get { return connectToVnets; }
            set { connectToVnets = value; }
        }

        public List<IPAddress> DnsServers
        {
            get { return dnsServers; }
            set { dnsServers = value; }
        }

        public List<IPAddress> IssuedIpAddresses
        {
            get { return issuedIpAddresses; }
            set { issuedIpAddresses = value; }
        }

        public VirtualNetwork()
        {
            SwitchType = SwitchType.Internal;
        }

        public override string ToString()
        {
            return name;
        }

        public IPAddress NextIpAddress()
        {
            IPAddress ip = null;

            if (issuedIpAddresses.Count == 0)
            {
                ip = addressSpace.Network.Increment().Increment().Increment();
                issuedIpAddresses.Add(ip);
            }
            else
            {
                ip = issuedIpAddresses.TakeLast().Increment();
                issuedIpAddresses.Add(ip);
            }

            while (HostType == VirtualizationHost.Azure && issuedIpAddresses.Count < 5)
            {
                ip = issuedIpAddresses.TakeLast().Increment();
                issuedIpAddresses.Add(ip);
            }

            ip.isAutoGenerated = true;
            return ip;
        }
    }
}
