using System;
using System.Linq;
using System.Xml.Serialization;

namespace AutomatedLab
{
    [Serializable]
    public partial class IPAddress
    {
        private System.Net.IPAddress ip;

        public static IPAddress Any { get { return System.Net.IPAddress.Any; } }
        public static IPAddress Broadcast { get { return System.Net.IPAddress.Broadcast; } }
        public static IPAddress IPv6Any { get { return System.Net.IPAddress.IPv6Any; } }
        public static IPAddress IPv6Loopback { get { return System.Net.IPAddress.IPv6Loopback; } }
        public static IPAddress IPv6None { get { return System.Net.IPAddress.IPv6None; } }
        public static IPAddress Loopback { get { return System.Net.IPAddress.Loopback; } }
        public static IPAddress None { get { return System.Net.IPAddress.None; } }

        [XmlAttribute]
        public string AddressAsString
        {
            get
            {
                return ip.ToString();
            }
            set
            {
                ip = Parse(value);
            }
        }

        public System.Net.Sockets.AddressFamily AddressFamily { get { return ip.AddressFamily; } }

        public bool IsIPv4MappedToIPv6 { get { return ip.IsIPv4MappedToIPv6; } }

        public bool IsIPv6LinkLocal { get { return ip.IsIPv6LinkLocal; } }

        public bool IsIPv6Multicast { get { return ip.IsIPv6Multicast; } }

        public bool IsIPv6SiteLocal { get { return ip.IsIPv6SiteLocal; } }

        public bool IsIPv6Teredo { get { return ip.IsIPv6Teredo; } }

        [XmlIgnore]
        public long? ScopeId
        {
            get
            {
                try
                {
                    return ip.ScopeId;
                }
                catch
                {
                    return null;
                }
            }
            set
            {
                if (value.HasValue)
                    ip.ScopeId = value.Value;
            }
        }

        public static int HostToNetworkOrder(int host)
        {
            return System.Net.IPAddress.HostToNetworkOrder(host);
        }

        public static short HostToNetworkOrder(short host)
        {
            return System.Net.IPAddress.HostToNetworkOrder(host);
        }

        public static long HostToNetworkOrder(long host)
        {
            return System.Net.IPAddress.HostToNetworkOrder(host);
        }

        public static bool IsLoopback(IPAddress address)
        {
            return System.Net.IPAddress.IsLoopback(address);
        }

        public static int NetworkToHostOrder(int network)
        {
            return System.Net.IPAddress.NetworkToHostOrder(network);
        }

        public static short NetworkToHostOrder(short network)
        {
            return System.Net.IPAddress.NetworkToHostOrder(network);
        }

        public static long NetworkToHostOrder(long network)
        {
            return System.Net.IPAddress.NetworkToHostOrder(network);
        }

        public static IPAddress Parse(string ipString)
        {
            IPAddress address = None;

            address = System.Net.IPAddress.Parse(ipString);

            return address;
        }

        public static bool TryParse(string ipString, out IPAddress address)
        {
            System.Net.IPAddress ip = None;
            address = None;

            var result = System.Net.IPAddress.TryParse(ipString, out ip);

            if (result)
            {
                address = ip;
            }

            return result;
        }

        public override bool Equals(object comparand)
        {
            var ip = comparand as IPAddress;

            if (ip == null)
                return false;

            var bytes1 = GetAddressBytes();
            var bytes2 = ip.GetAddressBytes();

            return bytes1.SequenceEqual(bytes2);
        }

        public byte[] GetAddressBytes()
        {
            return ip.GetAddressBytes();
        }

        public override int GetHashCode()
        {
            return ip.GetHashCode();
        }

        public IPAddress MapToIPv4()
        {
            return ip.MapToIPv4();
        }

        public IPAddress MapToIPv6()
        {
            return ip.MapToIPv6();
        }

        public IPAddress()
        {
            ip = new System.Net.IPAddress(0);
        }

        public IPAddress(long newAddress)
        {
            ip = new System.Net.IPAddress(newAddress);
        }

        public IPAddress(byte[] address)
        {
            ip = new System.Net.IPAddress(address);
        }

        public IPAddress(byte[] address, long scopeid)
        {
            ip = new System.Net.IPAddress(address, scopeid);
        }

        public override string ToString()
        {
            return ip.ToString();
        }
    }
}