//using System;
//using System.Collections.Generic;
//using System.Linq;
//using System.Net;
//using System.Text;
//using System.Threading.Tasks;

//namespace AutomatedLab
//{
//    class IpConfig
//    {
//        private int prefix;
//        private IPAddress address;

//        public int Prefix
//        {
//            get { return prefix; }
//        }

//        public IPAddress IpAddress
//        {
//            get { return address; }
//        }

//        public IPAddress Subnet
//        {
//            get
//            {
//                var bitmask = new string('1', prefix).PadRight(32, '0');
//                var addressAsInt = Convert.ToUInt32(bitmask, 2);

//                return this.ConvertDecimalToIpAddress(addressAsInt);
//            }
//        }

//        public IPAddress NetworkAddress
//        {
//            get
//            {
//                //Return ConvertTo-DottedDecimalIP ((ConvertTo-DecimalIP $IPAddress) -BAnd (ConvertTo-DecimalIP $SubnetMask))
//                return IPAddress.Any;
//            }
//        }

//        public IpConfig(IPAddress address, int prefix)
//        {
//            this.address = address;
//            this.prefix = prefix;
//        }

//        public IpConfig(IPAddress address, IPAddress subnet)
//        {
//            this.address = address;

//            this.prefix = subnet.GetAddressBytes().ForEach(b => Convert.ToString(b, 2)).Aggregate((a, b) => a + b).Count(c => c == '1');
//        }

//        private IPAddress ConvertDecimalToIpAddress(UInt32 address)
//        {
//            List<string> elements = new List<string>();

//            for (int i = 3; i > -1; i--)
//            {
//                UInt32 remainder = Convert.ToUInt32(address % Math.Pow(256, i));
//                var element = Convert.ToUInt32((address - remainder) / Math.Pow(256, i));
//                elements.Add(element.ToString());
//                address = remainder;
//            }

//            return IPAddress.Parse(string.Join(".", elements));
//        }

//        private UInt32 ConvertIpAddressToDecimalAddress(IPAddress ipAddress)
//        {
//            var i = 3;
//            UInt32 decimalIp = 0;

//            foreach (var b in ipAddress.GetAddressBytes())
//            {
//                decimalIp += (UInt32)(b * Math.Pow(256, i));
//                i--;
//            }

//            return decimalIp;
//        }
//    }
//}