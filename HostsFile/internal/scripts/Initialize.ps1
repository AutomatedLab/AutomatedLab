$script:hostFilePath = if ($PSEdition -eq 'Desktop' -or $IsWindows)
{
    "$($env:SystemRoot)\System32\drivers\etc\hosts"
}
elseif ($PSEdition -eq 'Core' -and $IsLinux)
{
    '/etc/hosts'
}

$type = @'
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace System.Net
{
    public class HostRecord
    {
        private IPAddress ipAddress;
        private string hostName;

        public IPAddress IpAddress
        {
            get { return ipAddress; }
            set { ipAddress = value; }
        }

        public string HostName
        {
            get { return hostName; }
            set { hostName = value; }
        }

        public HostRecord(IPAddress ipAddress, string hostName)
        {
            this.ipAddress = ipAddress;
            this.hostName = hostName;
        }

        public HostRecord(string ipAddress, string hostName)
        {
            this.ipAddress = IPAddress.Parse(ipAddress);
            this.hostName = hostName;
        }

        public override string ToString()
        {
            return string.Format("{0}\t{1}", this.ipAddress.ToString(), this.hostName);
        }

        public override bool Equals(object obj)
        {
            if (GetType() != obj.GetType())
                return false;

            var otherObject = (HostRecord)obj;

            if (this.hostName != otherObject.hostName)
                return false;

            return this.ipAddress.Equals(otherObject.ipAddress);
        }

        public override int GetHashCode()
        {
            return this.hostName.GetHashCode() ^ this.ipAddress.GetHashCode();
        }
    }
}
'@

Add-Type -TypeDefinition $type -ErrorAction SilentlyContinue