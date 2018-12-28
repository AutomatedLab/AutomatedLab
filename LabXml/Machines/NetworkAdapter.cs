using System;
using System.Collections.Generic;

namespace AutomatedLab
{
    [Serializable]
    public class NetworkAdapter
    {
        private VirtualNetwork virtualSwitch;
        private string interfaceName;
        private string macAddress;
        private List<IPNetwork> ipv4Address;
        private List<IPAddress> ipv4Gateway;
        private List<IPAddress> ipv4DnsServers;
        private List<IPNetwork> ipv6Address;
        private List<IPAddress> ipv6Gateway;
        private List<IPAddress> ipv6DnsServers;
        private string connectionSpecificDNSSuffix;
        private bool appendParentSuffix;
        private List<string> appendDNSSuffixes;
        private bool registerInDNS;
        private bool dnsSuffixInDnsRegistration;
        private bool enableLMHostsLookup;
        private NetBiosOptions netBIOSOptions;
        private bool useDhcp;
        private int accessVLANID;

        public VirtualNetwork VirtualSwitch
        {
            get { return virtualSwitch; }
            set { virtualSwitch = value; }
        }

        public string InterfaceName
        {
            get { return interfaceName; }
            set { interfaceName = value; }
        }
        public string MacAddress
        {
            get { return macAddress; }
            set { macAddress = value; }
        }

        public List<IPNetwork> Ipv4Address
        {
            get { return ipv4Address; }
            set { ipv4Address = value; }
        }

        public List<IPAddress> Ipv4Gateway
        {
            get { return ipv4Gateway; }
            set { ipv4Gateway = value; }
        }

        public List<IPAddress> Ipv4DnsServers
        {
            get { return ipv4DnsServers; }
            set { ipv4DnsServers = value; }
        }

        public List<IPNetwork> Ipv6Address
        {
            get { return ipv6Address; }
            set { ipv6Address = value; }
        }

        public List<IPAddress> Ipv6Gateway
        {
            get { return ipv6Gateway; }
            set { ipv6Gateway = value; }
        }

        public List<IPAddress> Ipv6DnsServers
        {
            get { return ipv6DnsServers; }
            set { ipv6DnsServers = value; }
        }

        public string ConnectionSpecificDNSSuffix
        {
            get { return connectionSpecificDNSSuffix; }
            set { connectionSpecificDNSSuffix = value; }
        }

        public bool AppendParentSuffixes
        {
            get { return appendParentSuffix; }
            set { appendParentSuffix = value; }
        }

        public List<string> AppendDNSSuffixes
        {
            get { return appendDNSSuffixes; }
            set { appendDNSSuffixes = value; }
        }

        public bool RegisterInDNS
        {
            get { return registerInDNS; }
            set { registerInDNS = value; }
        }

        public bool DnsSuffixInDnsRegistration
        {
            get { return dnsSuffixInDnsRegistration; }
            set { dnsSuffixInDnsRegistration = value; }
        }

        public NetBiosOptions NetBIOSOptions
        {
            get { return netBIOSOptions; }
            set { netBIOSOptions = value; }
        }

        public bool EnableLMHostsLookup
        {
            get { return enableLMHostsLookup; }
            set { enableLMHostsLookup = value; }
        }

        public bool UseDhcp
        {
            get { return useDhcp; }
            set { useDhcp = value; }
        }

        public int AccessVLANID
        {
            get { return accessVLANID; }
            set { accessVLANID = value; }
        }

        public NetworkAdapter()
        {
            ipv4Address = new List<IPNetwork>();
            ipv4Gateway = new List<IPAddress>();
            ipv4DnsServers = new List<IPAddress>();
            ipv6Address = new List<IPNetwork>();
            ipv6Gateway = new List<IPAddress>();
            ipv6DnsServers = new List<IPAddress>();
            appendDNSSuffixes = new List<string>();
        }
    }
}