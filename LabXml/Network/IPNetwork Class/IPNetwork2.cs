using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Sockets;
using System.Numerics;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Serialization;

namespace AutomatedLab
{
    public partial class IPNetwork
    {
        private IPAddress ipAddress;

        public static implicit operator IPNetwork(string ipString)
        {
            IPNetwork network;

            if (TryParse(ipString, out network))
            {
                return network;
            }
            else
                throw new InvalidCastException("The input string could not be parsed");
        }

        public IPNetwork()
        { }

        [XmlAttribute]
        public string SerializationNetworkAddress
        {
            get { return _ipaddress.ToString(); }
            set { _ipaddress = BigInteger.Parse(value); }
        }

        [XmlAttribute]
        public AddressFamily SerializationAddressFamily
        {
            get { return _family; }
            set { _family = value; }
        }

        [XmlAttribute]
        public byte SerializationCidr
        {
            get { return _cidr; }
            set { _cidr = value; }
        }

        [XmlElement]
        public IPAddress IpAddress
        {
            get { return ipAddress; }
            set { ipAddress = value; }
        }
    }
}
