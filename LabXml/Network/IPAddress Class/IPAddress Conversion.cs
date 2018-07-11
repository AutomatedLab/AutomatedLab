using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AutomatedLab
{
    public partial class IPAddress
    {
        //public IPAddress GetBroadcastAddress()
        //{
        //    byte[] ipAdressBytes = GetAddressBytes();
        //    byte[] subnetMaskBytes = Ipv4Subnet.GetAddressBytes();

        //    if (ipAdressBytes.Length != subnetMaskBytes.Length)
        //        throw new ArgumentException("Lengths of IP address and subnet mask do not match.");

        //    byte[] broadcastAddress = new byte[ipAdressBytes.Length];
        //    for (int i = 0; i < broadcastAddress.Length; i++)
        //    {
        //        broadcastAddress[i] = (byte)(ipAdressBytes[i] | (subnetMaskBytes[i] ^ 255));
        //    }
        //    return new IPAddress(broadcastAddress);
        //}

        //public IPAddress GetNetworkAddress()
        //{
        //    byte[] ipAdressBytes = ip.GetAddressBytes();
        //    byte[] subnetMaskBytes = Ipv4Subnet.GetAddressBytes();

        //    if (ipAdressBytes.Length != subnetMaskBytes.Length)
        //        throw new ArgumentException("Lengths of IP address and subnet mask do not match.");

        //    byte[] broadcastAddress = new byte[ipAdressBytes.Length];
        //    for (int i = 0; i < broadcastAddress.Length; i++)
        //    {
        //        broadcastAddress[i] = (byte)(ipAdressBytes[i] & (subnetMaskBytes[i]));
        //    }
        //    var networkAddress = new IPAddress(broadcastAddress);
        //    networkAddress.ipv4Prefix = ipv4Prefix;

        //    return networkAddress;
        //}


        //public bool IsInSameSubnet(IPAddress address)
        //{
        //    IPAddress network1 = GetNetworkAddress();
        //    IPAddress network2 = address.GetNetworkAddress();

        //    return network1.Equals(network2);
        //}

        //public uint ToDecimal()
        //{
        //    var i = 3;
        //    uint decimalIp = 0;

        //    foreach (var b in ip.GetAddressBytes())
        //    {
        //        decimalIp += Convert.ToUInt32(b * Math.Pow(256, i));
        //        i--;
        //    }

        //    return decimalIp;
        //}

        //public string ToBinary()
        //{
        //    var elements = ip.GetAddressBytes().ForEach(b => Convert.ToString(b, 2).PadLeft(8, '0')).ToArray();
        //    return string.Join(".", elements);
        //}

        public IPAddress Increment()
        {
            byte[] ip = GetAddressBytes();
            ip[3]++;
            if (ip[3] == 0)
            {
                ip[2]++;
                if (ip[2] == 0)
                {
                    ip[1]++;
                    if (ip[1] == 0)
                        ip[0]++;
                }
            }
            return new IPAddress(ip);
        }

        public IPAddress Increment(int iterations)
        {
            IPAddress tempIp = ip ;

            for (int i = 0; i < iterations; i++)
            {
                tempIp = tempIp.Increment();
            }

            return tempIp;
        }

        public IPAddress Decrement()
        {
            byte[] ip = GetAddressBytes();
            ip[3]--;
            if (ip[3] == 0)
            {
                ip[2]--;
                if (ip[2] == 0)
                {
                    ip[1]--;
                    if (ip[1] == 0)
                        ip[0]--;
                }
            }
            return new IPAddress(ip);
        }

        public IPAddress Decrement(int iterations)
        {
            IPAddress tempIp = ip;

            for (int i = 0; i < iterations; i++)
            {
                tempIp = tempIp.Decrement();
            }

            return tempIp;
        }

        public static implicit operator IPAddress(string ipString)
        {
            IPAddress ip;

            if (ipString.Contains("/"))
            {
                ipString = ipString.Substring(0, ipString.IndexOf('/'));
            }

            if (TryParse(ipString, out ip))
            {
                return ip;
            }
            else
                throw new InvalidCastException();
        }

        public static implicit operator System.Net.IPAddress(IPAddress ip)
        {
            return ip.ip;
        }

        public static implicit operator IPAddress(System.Net.IPAddress ip)
        {
            return new IPAddress(ip.GetAddressBytes());
        }

        public static  bool operator ==(IPAddress a, object b)
        {
            return Equals(a, b);
        }

        public static bool operator !=(IPAddress a, object b)
        {
            return !Equals(a, b);
        }
    }
}
