using System;
using System.Xml.Serialization;

namespace AutomatedLab
{
    public partial class IPAddress
    {
        //private int ipv4Prefix;

        //public int Ipv4Prefix
        //{
        //    get { return ipv4Prefix; }
        //    set { ipv4Prefix = value; }
        //}

        //public IPAddress Ipv4Subnet
        //{
        //    get
        //    {
        //        if (ipv4Prefix != 0)
        //        {
        //            return GetByNetBitLength(ipv4Prefix);
        //        }
        //        else
        //        {
        //            return "0.0.0.0";
        //        }
        //    }
        //}

        //public static IPAddress GetByHostBitLength(int hostpartLength)
        //{
        //    int hostPartLength = hostpartLength;
        //    int netPartLength = 32 - hostPartLength;

        //    if (netPartLength < 2)
        //        throw new ArgumentException("Number of hosts is to large for IPv4");

        //    byte[] binaryMask = new byte[4];

        //    for (int i = 0; i < 4; i++)
        //    {
        //        if (i * 8 + 8 <= netPartLength)
        //            binaryMask[i] = 255;
        //        else if (i * 8 > netPartLength)
        //            binaryMask[i] = 0;
        //        else
        //        {
        //            int oneLength = netPartLength - i * 8;
        //            string binaryDigit =
        //                string.Empty.PadLeft(oneLength, '1').PadRight(8, '0');
        //            binaryMask[i] = Convert.ToByte(binaryDigit, 2);
        //        }
        //    }
        //    return new IPAddress(binaryMask);
        //}

        //public static IPAddress GetByNetBitLength(int netpartLength)
        //{
        //    int hostPartLength = 32 - netpartLength;
        //    return GetByHostBitLength(hostPartLength);
        //}

        //public static IPAddress GetByHostNumber(int numberOfHosts)
        //{
        //    int maxNumber = numberOfHosts + 1;

        //    string b = Convert.ToString(maxNumber, 2);

        //    return GetByHostBitLength(b.Length);
        //}
    }
}