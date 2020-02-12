using System;
using System.Xml.Serialization;
using System.Collections.Generic;
using System.Linq;
using LabXml;

namespace AutomatedLab
{
    [Serializable]
    public class OperatingSystem
    {
        private string operatingSystemName;
        private string operatingSystemImageName;
        private string operatingSystemImageDescription;
        private string isoPath;
        private string baseDiskPath;
        private Version version;
        private DateTime publishedDate;
        private long size;
        private string edition;
        private string installation;
        private int imageIndex;
        private Dictionary<string, string> azureToIsoName = new Dictionary<string, string>(){
            {"2008-R2-SP1", "Windows Server 2008 R2 Datacenter (Full Installation)" },
            {"2012-Datacenter", "Windows Server 2012 Datacenter (Server with a GUI)" },
            {"2012-R2-Datacenter", "Windows Server 2012 R2 Datacenter (Server with a GUI)" },
            {"2016-Datacenter", "Windows Server 2016 Datacenter (Desktop Experience)" },
            {"2016-Datacenter-Server-Core", "Windows Server 2016 Datacenter" },
            {"2019-Datacenter", "Windows Server 2019 Datacenter (Desktop Experience)" },
            {"2019-Datacenter-Core", "Windows Server 2019 Datacenter" },
            {"Datacenter-Core-1803-with-Containers-smalldisk", "Windows Server Datacenter" },
            {"Win81-Ent-N-x64", "Windows 8.1 Enterprise" },
            {"Windows-10-N-x64", "Windows 10 Enterprise" },
            {"Win7-SP1-Ent-N-x64", "Windows 7 Enterprise" },
            {"rs4-pro", "Windows 10 Pro" }
            };
        private Dictionary<string, string> isoNameToAzureSku;

        private static ListXmlStore<ProductKey> productKeys = null;
        private static ListXmlStore<ProductKey> productKeysCustom = null;

        public string OperatingSystemName
        {
            get { return operatingSystemName; }
            set { operatingSystemName = value; }
        }

        public Version Version
        {
            get
            {
                if (version != null)
                {
                    return version;
                }
                else
                {
                    switch (VersionString)
                    {
                        case "2008":
                            return (IsR2 ? "6.1" : "6.0");
                        case "2012":
                            return (IsR2 ? "6.3" : "6.2");
                        case "2016":
                            return "10.0";
                        case "2019":
                            return "10.0";
                        case "7":
                            return "6.1";
                        case "8":
                            return "6.2";
                        case "8.1":
                            return "6.3";
                        case "10":
                            return "10.0";
                        case "":
                            if (operatingSystemName == "Windows Server Datacenter" |
                                operatingSystemName == "Windows Server Standard" |
                                operatingSystemName == "Windows Server Datacenter (Desktop Experience)" |
                                operatingSystemName == "Windows Server Standard (Desktop Experience)"
                                )
                                return "10.0";
                            throw new Exception("Operating System Version could not be retrieved");
                        default:
                            return VersionString;
                    }

                }
            }
            set { version = value; }
        }

        public DateTime PublishedDate
        {
            get { return publishedDate; }
            set { publishedDate = value; }
        }

        public long Size
        {
            get { return size; }
            set { size = value; }
        }

        public string Edition
        {
            get { return edition; }
            set { edition = value; }
        }

        public string Installation
        {
            get { return installation; }
            set { installation = value; }
        }

        public string AzureImageName
        {
            get
            {
                try
                {
                    return isoNameToAzureSku[OperatingSystemName];
                }
                catch (ArgumentNullException)
                {
                    // Key is null - can happen
                }
                catch (KeyNotFoundException)
                {
                    // OS not in dictionary - can happen
                }

                return string.Empty;
            }
        }

        public string VMWareImageName
        {
            get
            {
                //the VMWare templates must be provided by the VMWare infrastructure
                switch (operatingSystemName)
                {
                    case "Windows Server 2008 R2 Datacenter (Full Installation)":
                        return "AL_WindowsServer2008R2DataCenter";

                    case "Windows Server 2012 Datacenter (Server with a GUI)":
                        return "AL_WindowsServer2012DataCenter";

                    case "Windows Server 2012 R2 Datacenter (Server with a GUI)":
                        return "AL_WindowsServer2012R2DataCenter";

                    case "Windows Server vNext SERVERDATACENTER":
                        return "AL_WindowsServer10DataCenter";

                    default:
                        return string.Empty;
                }
            }
        }

        public string ProductKey
        {
            get
            {
                //get all keys mathing the OS name
                var keys = productKeys.Where(pk => pk.OperatingSystemName == operatingSystemImageName).OrderByDescending(pk => (Version)pk.Version);
                if (keys.Count() == 0)
                {
                    return "";
                }
                else if (keys.Count() == 1)
                {
                    return keys.FirstOrDefault().Key;
                }
                else //if there is more than one key
                {
                    // get the keys equals or greater thanthe OS version
                    var keysOsVersion = keys.Where(pk => pk.Version >= version).OrderByDescending(pk => (Version)pk.Version);

                    if (keysOsVersion.Count() == 0)
                    {
                        //if no keys are available for the specific version, try the one with the highest version for the given OS
                        keysOsVersion = keys.OrderByDescending(pk => (Version)pk.Version);
                    }

                    return keysOsVersion.First().Key;
                }
            }
        }

        public string IsoPath
        {
            get { return isoPath; }
            set { isoPath = value; }
        }

        public string IsoName
        {
            get { return System.IO.Path.GetFileNameWithoutExtension(isoPath); }
        }

        public string BaseDiskPath
        {
            get { return baseDiskPath; }
            set { baseDiskPath = value; }
        }

        [XmlArrayItem(ElementName = "Package")]
        public List<String> LinuxPackageGroup { get; set; }
        public OperatingSystem()
        {
            LinuxPackageGroup = new List<String>();
            isoNameToAzureSku = azureToIsoName.ToDictionary(kp => kp.Value, kp => kp.Key);
        }

        public OperatingSystem(string azureSkuName, bool azure = true)
        {
            isoNameToAzureSku = azureToIsoName.ToDictionary(kp => kp.Value, kp => kp.Key);

            try
            {
                operatingSystemName = azureToIsoName[azureSkuName];
            }
            catch (ArgumentNullException)
            {
                // Key is null - can happen
            }
            catch (KeyNotFoundException)
            {
                // OS not in dictionary - can happen
            }
        }

        static OperatingSystem()
        {
            string path = (string)PowerShellHelper.InvokeCommand("Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot").FirstOrDefault().BaseObject;

            string productKeysXmlFilePath = $@"{path}/Assets/ProductKeys.xml";
            string productKeysCusomXmlFilePath = string.Format(@"{0}/{1}",
                    path,
                    @"Assets/ProductKeysCustom.xml");
            try
            {
                productKeys = ListXmlStore<ProductKey>.Import(productKeysXmlFilePath);
            }
            catch (Exception ex)
            {
                throw new Exception(string.Format("Could not read 'ProductKeys.xml' file. Make sure the file exist in path '{0}': {1}", productKeysXmlFilePath, ex.Message));
            }

            try
            {
                productKeysCustom = ListXmlStore<ProductKey>.Import(productKeysCusomXmlFilePath);
            }
            catch (Exception)
            {
                //don't throw, the file is not mandatory
            }

            //merge keys from custom file
            foreach (var key in productKeysCustom)
            {
                var existingKey = productKeys.Where(pk => pk.OperatingSystemName == key.OperatingSystemName && pk.Version == key.Version);
                if (existingKey.Count() == 0)
                {
                    productKeys.Add(new ProductKey()
                    {
                        OperatingSystemName = key.OperatingSystemName,
                        Version = key.Version,
                        Key = key.Key
                    });
                }
                else if (existingKey.Count() == 1)
                {
                    existingKey.First().Key = key.Key;
                }
                else
                { }
            }
        }

        public OperatingSystem(string operatingSystemName)
        {
            isoNameToAzureSku = azureToIsoName.ToDictionary(kp => kp.Value, kp => kp.Key);
            this.operatingSystemName = operatingSystemName;
            LinuxPackageGroup = new List<String>();
            if (operatingSystemName.ToLower().Contains("windows server"))
            {
                installation = "Server";
            }
            else
            {
                installation = "Client";
            }
        }

        public OperatingSystem(string operatingSystemName, AutomatedLab.Version version)
            : this(operatingSystemName)
        {
            LinuxPackageGroup = new List<String>();
            this.version = version;
        }

        public OperatingSystem(string operatingSystemName, string isoPath)
            : this(operatingSystemName)
        {
            LinuxPackageGroup = new List<String>();
            this.isoPath = isoPath;
        }

        public OperatingSystem(string operatingSystemName, string isoPath, Version version)
            : this(operatingSystemName)
        {
            LinuxPackageGroup = new List<String>();
            this.isoPath = isoPath;
            this.version = version;
        }

        public OperatingSystem(string operatingSystemName, string isoPath, Version version, string imageName)
            : this(operatingSystemName)
        {
            LinuxPackageGroup = new List<String>();
            this.isoPath = isoPath;
            this.version = version;
            this.operatingSystemImageName = imageName;
        }

        public override string ToString()
        {
            return operatingSystemName;
        }

        public LinuxType LinuxType
        {
            get
            {
                return (System.Text.RegularExpressions.Regex.IsMatch(OperatingSystemName, "CentOS|Red Hat|Fedora")) ? LinuxType.RedHat : LinuxType.SuSE;
            }
        }
        public OperatingSystemType OperatingSystemType
        {
            get
            {
                if (OperatingSystemName.Contains("Windows"))
                {
                    return OperatingSystemType.Windows;
                }
                else if (OperatingSystemName.Contains("Hyper-V"))
                {
                    return OperatingSystemType.Windows;
                }
                else
                {
                    return OperatingSystemType.Linux;
                }
            }
        }
        public string OperatingSystemImageName
        {
            get { return operatingSystemImageName; }
            set { operatingSystemImageName = value; }
        }

        public string OperatingSystemImageDescription
        {
            get { return operatingSystemImageDescription; }
            set { operatingSystemImageDescription = value; }
        }

        public int ImageIndex
        {
            get { return imageIndex; }
            set { imageIndex = value; }
        }

        public override bool Equals(object obj)
        {
            var os = obj as OperatingSystem;

            if (os == null)
                return false;

            return operatingSystemName == os.operatingSystemName &&
                version == os.version &&
                edition == os.edition &&
                installation == os.installation;
        }

        public static bool operator >(OperatingSystem o1, OperatingSystem o2)
        {
            return o1.Version > o2.Version;
        }
        public static bool operator <(OperatingSystem o1, OperatingSystem o2)
        {
            return o1.Version < o2.Version;
        }

        public static implicit operator string(OperatingSystem os)
        {
            return os.ToString();
        }

        public override int GetHashCode()
        {
            return base.GetHashCode();
        }

        private string VersionString
        {
            get
            {
                var exp = @"(?:Windows Server )?(\d{4})(( )?R2)?|(?:Windows )?((\d){1,2}(\.\d)?)|(?:(CentOS |Fedora |Red Hat Enterprise Linux |openSUSE Leap |SUSE Linux Enterprise Server ))?(\d+\.?\d?)((?: )?SP\d)?";

                var match = System.Text.RegularExpressions.Regex.Match(operatingSystemName, exp, System.Text.RegularExpressions.RegexOptions.IgnoreCase);

                if (!string.IsNullOrEmpty(match.Groups[1].Value))
                {
                    return match.Groups[1].Value;
                }
                else if (!string.IsNullOrEmpty(match.Groups[4].Value))
                {
                    return match.Groups[4].Value;
                }
                else
                {
                    if (!string.IsNullOrEmpty(match.Groups[9].Value))
                    {
                        return $"{match.Groups[8].Value}.{match.Groups[9].Value[match.Groups[9].Value.Length - 1]}";
                    }
                    return match.Groups[8].Value;
                }
            }
        }

        private bool IsR2
        {
            get
            {
                var exp = @"(WS)?(?:\d{4}( )?)(?<IsR2>R2)";

                var match = System.Text.RegularExpressions.Regex.Match(operatingSystemName, exp);

                if (!string.IsNullOrEmpty(match.Groups["IsR2"].Value))
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
        }
    }
}
