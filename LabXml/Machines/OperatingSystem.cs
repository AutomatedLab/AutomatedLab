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

        private static ListXmlStore<ProductKey> productKeys = null;
        private static ListXmlStore<ProductKey> productKeysCustom = null;

        public Architecture Architecture { get; set; }
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
                        case "2022":
                            return "10.0";
                        case "2025":
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
            Architecture = Architecture.Unknown;
        }

        public OperatingSystem(string azureSkuName, bool azure = true)
        {
            Architecture = Architecture.Unknown;
            AzureImageName = azureSkuName;

            try
            {
                operatingSystemName = OsNameFromAzureString(azureSkuName);
            }
            catch { }
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
            this.operatingSystemName = operatingSystemName;
            LinuxPackageGroup = new List<String>();
            Architecture = Architecture.Unknown;
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
                if (System.Text.RegularExpressions.Regex.IsMatch(OperatingSystemName, "CentOS|Red Hat|Fedora")) return LinuxType.RedHat;
                if (System.Text.RegularExpressions.Regex.IsMatch(OperatingSystemName, "Suse")) return LinuxType.SuSE;
                if (System.Text.RegularExpressions.Regex.IsMatch(OperatingSystemName, "Ubuntu|Kali")) return LinuxType.Ubuntu;

                return LinuxType.Unknown;
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

        public string AzureImageName { get; set; }

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
                Architecture == os.Architecture &&
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

        private string OsNameFromAzureString(string azureSkuName)
        {
            // Return OS name AutomatedLab uses from one of the many, many, Azure SKU names
            switch (azureSkuName)
            {
                case "windows-server-2022-azure-edition-preview-core_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter";
                case "windows-server-2022-g2_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter (Desktop Experience)";
                case "windows-server-vnext-azure-edition_microsoftwindowsserver":
                    return "Windows Server 2025 Datacenter (Desktop Experience)";
                case "windows-server-vnext-azure-edition-core_microsoftwindowsserver":
                    return "Windows Server 2025 Datacenter";
                case "2012-datacenter_microsoftwindowsserver":
                    return "Windows Server 2012 Datacenter (Server with a GUI)";
                case "2012-datacenter-gensecond_microsoftwindowsserver":
                    return "Windows Server 2012 Datacenter (Server with a GUI)";
                case "2012-r2-datacenter_microsoftwindowsserver":
                    return "Windows Server 2012 R2 Datacenter (Server with a GUI)";
                case "2012-r2-datacenter-gensecond_microsoftwindowsserver":
                    return "Windows Server R2 2012 Datacenter (Server with a GUI)";
                case "2016-datacenter_microsoftwindowsserver":
                    return "Windows Server 2016 Datacenter (Desktop Experience)";
                case "2016-datacenter-gensecond_microsoftwindowsserver":
                    return "Windows Server 2016 Datacenter (Desktop Experience)";
                case "2016-datacenter-server-core_microsoftwindowsserver":
                    return "Windows Server 2016 Datacenter";
                case "2016-datacenter-server-core-g2_microsoftwindowsserver":
                    return "Windows Server 2016 Datacenter";
                case "2019-datacenter_microsoftwindowsserver":
                    return "Windows Server 2019 Datacenter (Desktop Experience)";
                case "2019-datacenter-core_microsoftwindowsserver":
                    return "Windows Server 2019 Datacenter";
                case "2019-datacenter-core-g2_microsoftwindowsserver":
                    return "Windows Server 2019 Datacenter";
                case "2019-datacenter-gensecond_microsoftwindowsserver":
                    return "Windows Server 2019 Datacenter (Desktop Experience)";
                case "2019-datacenter-gs_microsoftwindowsserver":
                    return "Windows Server 2019 Datacenter";
                case "2019-datacenter-gs-g2_microsoftwindowsserver":
                    return "Windows Server 2019 Datacenter";
                case "2022-datacenter_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter (Desktop Experience)";
                case "2022-datacenter-azure-edition_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter (Desktop Experience)";
                case "2022-datacenter-azure-edition-core_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter";
                case "2022-datacenter-azure-edition-hotpatch_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter (Desktop Experience)";
                case "2022-datacenter-core_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter";
                case "2022-datacenter-core-g2_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter";
                case "2022-datacenter-g2_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter (Desktop Experience)";
                case "23h2-datacenter-core_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter";
                case "23h2-datacenter-core-g2_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter";
                case "2016-datacenter-gen2_microsoftwindowsserver":
                    return "Windows Server 2016 Datacenter (Desktop Experience)";
                case "20_04-lts_canonical":
                    return "Ubuntu Server 20.04 LTS \"Focal Fossa\"";
                case "20_04-lts-gen2_canonical":
                    return "Ubuntu Server 20.04 LTS \"Focal Fossa\"";
                case "20_10-gen2_canonical":
                    return "Ubuntu Server 20.10 \"Groovy Gorilla\"";
                case "22_04-lts_canonical":
                    return "Ubuntu Server 22.04 LTS \"Jammy Jellyfish\"";
                case "22_04-lts-gen2_canonical":
                    return "Ubuntu Server 22.04 LTS \"Jammy Jellyfish\"";
                case "23_04_canonical":
                    return "Ubuntu Server 23.04 \"Lunar Lobster\"";
                case "23_04-gen2_canonical":
                    return "Ubuntu Server 23.04 \"Lunar Lobster\"";
                case "23_10_canonical":
                    return "Ubuntu Server 23.10 \"Mantic Minotaur\"";
                case "23_10-gen2_canonical":
                    return "Ubuntu Server 23.10 \"Mantic Minotaur\"";
                case "7.4_redhat":
                    return "Red Hat Enterprise Linux 7.4";
                case "7.5_redhat":
                    return "Red Hat Enterprise Linux 7.5";
                case "7.6_redhat":
                    return "Red Hat Enterprise Linux 7.6";
                case "7.7_redhat":
                    return "Red Hat Enterprise Linux 7.7";
                case "7.8_redhat":
                    return "Red Hat Enterprise Linux 7.8";
                case "74-gen2_redhat":
                    return "Red Hat Enterprise Linux 7.4";
                case "75-gen2_redhat":
                    return "Red Hat Enterprise Linux 7.5";
                case "76-gen2_redhat":
                    return "Red Hat Enterprise Linux 7.6";
                case "77-gen2_redhat":
                    return "Red Hat Enterprise Linux 7.7";
                case "78-gen2_redhat":
                    return "Red Hat Enterprise Linux 7.8";
                case "79-gen2_redhat":
                    return "Red Hat Enterprise Linux 7.9";
                case "7_9_redhat":
                    return "Red Hat Enterprise Linux 7.9";
                case "8_redhat":
                    return "Red Hat Enterprise Linux 8.0";
                case "8.1_redhat":
                    return "Red Hat Enterprise Linux 8.1";
                case "8.2_redhat":
                    return "Red Hat Enterprise Linux 8.2";
                case "810-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.10";
                case "81gen2_redhat":
                    return "Red Hat Enterprise Linux 8.1";
                case "82gen2_redhat":
                    return "Red Hat Enterprise Linux 8.2";
                case "83-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.3";
                case "84-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.4";
                case "85-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.5";
                case "86-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.6";
                case "87-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.7";
                case "88-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.8";
                case "89-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.9";
                case "8_10_redhat":
                    return "Red Hat Enterprise Linux 8.10";
                case "8_3_redhat":
                    return "Red Hat Enterprise Linux 8.3";
                case "8_4_redhat":
                    return "Red Hat Enterprise Linux 8.4";
                case "8_5_redhat":
                    return "Red Hat Enterprise Linux 8.5";
                case "8_6_redhat":
                    return "Red Hat Enterprise Linux 8.6";
                case "8_7_redhat":
                    return "Red Hat Enterprise Linux 8.7";
                case "8_8_redhat":
                    return "Red Hat Enterprise Linux 8.8";
                case "8_9_redhat":
                    return "Red Hat Enterprise Linux 8.9";
                case "90-gen2_redhat":
                    return "Red Hat Enterprise Linux 9.0";
                case "91-gen2_redhat":
                    return "Red Hat Enterprise Linux 9.1";
                case "92-gen2_redhat":
                    return "Red Hat Enterprise Linux 9.2";
                case "93-gen2_redhat":
                    return "Red Hat Enterprise Linux 9.3";
                case "94_gen2_redhat":
                    return "Red Hat Enterprise Linux 9.4";
                case "9_0_redhat":
                    return "Red Hat Enterprise Linux 9.0";
                case "9_1_redhat":
                    return "Red Hat Enterprise Linux 9.1";
                case "9_2_redhat":
                    return "Red Hat Enterprise Linux 9.2";
                case "9_3_redhat":
                    return "Red Hat Enterprise Linux 9.3";
                case "9_4_redhat":
                    return "Red Hat Enterprise Linux 9.4";
                case "6.10_openlogic":
                    return "CentOS 6.10";
                case "6.9_openlogic":
                    return "CentOS 6.9";
                case "7.3_openlogic":
                    return "CentOS 7.3";
                case "7.4_openlogic":
                    return "CentOS 7.4";
                case "7.5_openlogic":
                    return "CentOS 7.5";
                case "7.6_openlogic":
                    return "CentOS 7.6";
                case "7.7_openlogic":
                    return "CentOS 7.7";
                case "7_4_openlogic":
                    return "CentOS 7.4";
                case "7_4-gen2_openlogic":
                    return "CentOS 7.4";
                case "7_5-gen2_openlogic":
                    return "CentOS 7.5";
                case "7_6-gen2_openlogic":
                    return "CentOS 7.6";
                case "7_7-gen2_openlogic":
                    return "CentOS 7.7";
                case "7_8_openlogic":
                    return "CentOS 7.8";
                case "7_8-gen2_openlogic":
                    return "CentOS 7.8";
                case "7_9_openlogic":
                    return "CentOS 7.9";
                case "7_9-gen2_openlogic":
                    return "CentOS 7.9";
                case "8.0_openlogic":
                    return "CentOS 8.0";
                case "8_0-gen2_openlogic":
                    return "CentOS 8.0";
                case "8_1_openlogic":
                    return "CentOS 8.1";
                case "8_1-gen2_openlogic":
                    return "CentOS 8.1";
                case "8_2_openlogic":
                    return "CentOS 8.2";
                case "8_2-gen2_openlogic":
                    return "CentOS 8.2";
                case "8_3_openlogic":
                    return "CentOS 8.3";
                case "8_3-gen2_openlogic":
                    return "CentOS 8.3";
                case "8_4_openlogic":
                    return "CentOS 8.4";
                case "8_4-gen2_openlogic":
                    return "CentOS 8.4";
                case "8_5_openlogic":
                    return "CentOS 8.5";
                case "8_5-gen2_openlogic":
                    return "CentOS 8.5";
                case "kali-2023-3_kali-linux":
                    return "Kali Linux 2023.3";
                case "kali-2023-4_kali-linux":
                    return "Kali Linux 2023.4";
                case "19h1-ent-gensecond_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "19h1-entn-gensecond_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "19h1-pro-gensecond_microsoftwindowsdesktop":
                    return "Windows 10 Pro";
                case "19h1-pron-gensecond_microsoftwindowsdesktop":
                    return "Windows 10 Pro N";
                case "19h2-pro-g2_microsoftwindowsdesktop":
                    return "Windows 10 Pro";
                case "19h2-pron-g2_microsoftwindowsdesktop":
                    return "Windows 10 Pro N";
                case "20h2-ent_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "20h2-ent-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "20h2-entn_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "20h2-entn-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "rs1-enterprise_microsoftwindowsdesktop": // 1607
                    return "Windows 10 Enterprise";
                case "rs1-enterprise-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "rs1-enterprisen_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "rs1-enterprisen-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "rs5-enterprise_microsoftwindowsdesktop": // 1809
                    return "Windows 10 Enterprise";
                case "rs5-enterprise-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "rs5-enterprise-standard-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "rs5-enterprisen_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "rs5-enterprisen-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "rs5-enterprisen-standard-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "win10-21h2-ent_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "win10-21h2-ent-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "win10-21h2-ent-ltsc_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise LTSC";
                case "win10-21h2-ent-ltsc-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise LTSC";
                case "win10-21h2-entn_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "win10-21h2-entn-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "win10-21h2-entn-ltsc_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N LTSC";
                case "win10-21h2-entn-ltsc-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N LTSC";
                case "win10-21h2-pro_microsoftwindowsdesktop":
                    return "Windows 10 Pro";
                case "win10-21h2-pro-g2_microsoftwindowsdesktop":
                    return "Windows 10 Pro";
                case "win10-21h2-pron_microsoftwindowsdesktop":
                    return "Windows 10 Pro N";
                case "win10-21h2-pron-g2_microsoftwindowsdesktop":
                    return "Windows 10 Pro N";
                case "win10-22h2-ent_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "win10-22h2-ent-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "win10-22h2-entn_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "win10-22h2-entn-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "win10-22h2-pro_microsoftwindowsdesktop":
                    return "Windows 10 Pro";
                case "win10-22h2-pro-g2_microsoftwindowsdesktop":
                    return "Windows 10 Pro";
                case "win10-22h2-pron_microsoftwindowsdesktop":
                    return "Windows 10 Pro N";
                case "win10-22h2-pron-g2_microsoftwindowsdesktop":
                    return "Windows 10 Pro N";
                case "win11-21h2-entn_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise N";
                case "win11-21h2-pron_microsoftwindowsdesktop":
                    return "Windows 11 Pro N";
                case "win11-22h2-entn_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise N";
                case "win11-22h2-pron_microsoftwindowsdesktop":
                    return "Windows 11 Pro N";
                case "win11-23h2-entn_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise N";
                case "win11-23h2-pron_microsoftwindowsdesktop":
                    return "Windows 11 Pro N";
                case "win11-24h2-entn_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise N";
                case "win11-24h2-pron_microsoftwindowsdesktop":
                    return "Windows 11 Pro N";
                case "win11-21h2-ent_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise";
                case "win11-21h2-pro_microsoftwindowsdesktop":
                    return "Windows 11 Pro";
                case "win11-22h2-ent_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise";
                case "win11-22h2-pro_microsoftwindowsdesktop":
                    return "Windows 11 Pro";
                case "win11-23h2-ent_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise";
                case "win11-23h2-pro_microsoftwindowsdesktop":
                    return "Windows 11 Pro";
                case "win11-24h2-ent_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise";
                case "win11-24h2-pro_microsoftwindowsdesktop":
                    return "Windows 11 Pro";
                default:
                    return string.Empty;
            }
        }
    }
}
