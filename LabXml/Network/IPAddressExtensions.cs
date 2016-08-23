using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;

namespace AutomatedLab
{
    public static class SubnetHelper
    {
        public static readonly IPAddress ClassA = "255.0.0.0";
        public static readonly IPAddress ClassB = "255.255.0.0";
        public static readonly IPAddress ClassC = "255.255.255.0";

        public static IPAddress CreateByHostBitLength(int hostpartLength)
        {
            int hostPartLength = hostpartLength;
            int netPartLength = 32 - hostPartLength;

            if (netPartLength < 2)
                throw new ArgumentException("Number of hosts is to large for IPv4");

            byte[] binaryMask = new byte[4];

            for (int i = 0; i < 4; i++)
            {
                if (i * 8 + 8 <= netPartLength)
                    binaryMask[i] = 255;
                else if (i * 8 > netPartLength)
                    binaryMask[i] = 0;
                else
                {
                    int oneLength = netPartLength - i * 8;
                    string binaryDigit =
                        string.Empty.PadLeft(oneLength, '1').PadRight(8, '0');
                    binaryMask[i] = Convert.ToByte(binaryDigit, 2);
                }
            }
            return new IPAddress(binaryMask);
        }

        public static IPAddress CreateByNetBitLength(int netpartLength)
        {
            int hostPartLength = 32 - netpartLength;
            return CreateByHostBitLength(hostPartLength);
        }

        public static IPAddress CreateByHostNumber(int numberOfHosts)
        {
            int maxNumber = numberOfHosts + 1;

            string b = Convert.ToString(maxNumber, 2);

            return CreateByHostBitLength(b.Length);
        }
    }
}