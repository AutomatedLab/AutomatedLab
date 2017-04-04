using System;

namespace AutomatedLab
{
    [Serializable]
    public class OperatingSystem
    {
        private string operatingSystemName;
        private string operatingSystemImageName;
        private string isoPath;
        private string baseDiskPath;
        private Version version;
        private DateTime publishedDate;
        private long size;
        private string edition;
        private string installation;
        private int imageIndex;

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
                        case "7":
                            return "6.1";
                        case "8":
                            return "6.2";
                        case "8.1":
                            return "6.3";
                        case "10":
                            return "10.0";
                        default:
                            throw new Exception("Operating System Version could not be retrieved");
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
                //updating the list by getting the current list if Azure-VMImages:
                //Get-AzureVMImage | Where-Object OS -eq Windows | Group-Object -Property Imagefamily | ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 } | Format-Table -Property Imagefamily, PublishedDate

                switch (operatingSystemName)
                {
                    case "Windows Server 2008 R2 SERVERDATACENTER":
                        return "2008-R2-SP1";

                    case "Windows Server 2012 SERVERDATACENTER":
                        return "2012-Datacenter";

                    case "Windows Server 2012 R2 SERVERDATACENTER":
                        return "2012-R2-Datacenter";

                    case "Windows Server 2016 SERVERDATACENTER":
                        return "2016-Datacenter";

                    case "Windows Server 2016 SERVERSTANDARDNANO":
                        return "2016-Nano-Server";
                        
                    case "Windows 8.1 Enterprise":
                        return "Win8.1-Ent-N";

                    case "Windows 10 Pro":
                        return "Windows-10-N-x64";

                    case "Windows 10 Enterprise":
                        return "Windows-10-N-x64";

                    case "Windows 7 ENTERPRISE":
                        return "Win7-SP1-Ent-N";

                    default:
                        return string.Empty;
                }
            }
        }

        public string VMWareImageName
        {
            get
            {
                //the VMWare templates must be provided by the VMWare infrastructure
                switch (operatingSystemName)
                {
                    case "Windows Server 2008 R2 SERVERDATACENTER":
                        return "AL_WindowsServer2008R2DataCenter";

                    case "Windows Server 2012 SERVERDATACENTER":
                        return "AL_WindowsServer2012DataCenter";

                    case "Windows Server 2012 R2 SERVERDATACENTER":
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
                switch (operatingSystemName)
                {
                    case "Windows 7 PROFESSIONAL":
                        return "FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4";
                    case "Windows 7 ENTERPRISE":
                        return "33PXH-7Y6KF-2VJC9-XBBR8-HVTHH";

                    case "Windows 8 Pro":
                        return "NG4HW-VH26C-733KW-K6F98-J8CK4";
                    case "Windows 8 Enterprise":
                        return "32JNW-9KQ84-P47T8-D8GGY-CWCK7";

                    case "Windows 8.1 Pro":
                        return "GCRJD-8NW9H-F2CDX-CCM8D-9D6T9";
                    case "Windows 8.1 Enterprise":
                        return "MHF9N-XY6XB-WVXMC-BTDCT-MKKG7";

                    case "Windows Server 2008 R2 SERVERSTANDARD":
                        return "YC6KT-GKW9T-YTKYR-T4X34-R7VHC";
                    case "Windows Server 2008 R2 SERVERSTANDARDCORE":
                        return "YC6KT-GKW9T-YTKYR-T4X34-R7VHC";
                    case "Windows Server 2008 R2 SERVERENTERPRISE":
                        return "489J6-VHDMP-X63PK-3K798-CPX3Y";
                    case "Windows Server 2008 R2 SERVERENTERPRISECORE":
                        return "489J6-VHDMP-X63PK-3K798-CPX3Y";
                    case "Windows Server 2008 R2 SERVERDATACENTER":
                        return "74YFP-3QFB3-KQT8W-PMXWJ-7M648";
                    case "Windows Server 2008 R2 SERVERDATACENTERCORE":
                        return "74YFP-3QFB3-KQT8W-PMXWJ-7M648";
                    case "Windows Server 2008 R2 SERVERWEB":
                        return "6TPJF-RBVHG-WBW2R-86QPH-6RTM4";
                    case "Windows Server 2008 R2 SERVERWEBCORE":
                        return "6TPJF-RBVHG-WBW2R-86QPH-6RTM4";

                    case "Windows Server 2012 SERVERSTANDARDCORE":
                        return "XC9B7-NBPP2-83J2H-RHMBY-92BT4";
                    case "Windows Server 2012 SERVERSTANDARD":
                        return "XC9B7-NBPP2-83J2H-RHMBY-92BT4";
                    case "Windows Server 2012 SERVERDATACENTERCORE":
                        return "48HP8-DN98B-MYWDG-T2DCC-8W83P";
                    case "Windows Server 2012 SERVERDATACENTER":
                        return "48HP8-DN98B-MYWDG-T2DCC-8W83P";

                    case "Windows Server 2012 R2 SERVERSTANDARDCORE":
                        return "DBGBW-NPF86-BJVTX-K3WKJ-MTB6V";
                    case "Windows Server 2012 R2 SERVERSTANDARD":
                        return "DBGBW-NPF86-BJVTX-K3WKJ-MTB6V";
                    case "Windows Server 2012 R2 SERVERDATACENTERCORE":
                        return "Y4TGP-NPTV9-HTC2H-7MGQ3-DV4TW";
                    case "Windows Server 2012 R2 SERVERDATACENTER":
                        return "Y4TGP-NPTV9-HTC2H-7MGQ3-DV4TW";

                    case "Windows 10 Pro":
                        return "W269N-WFGWX-YVC9B-4J6C9-T83GX";
                    case "Windows 10 Pro Technical Preview":
                        return "W269N-WFGWX-YVC9B-4J6C9-T83GX";
                    case "Windows 10 Enterprise":
                        return "NPPR9-FWDCX-D2C8J-H872K-2YT43";
                    case "Windows 10 Enterprise Technical Preview":
                        return "NPPR9-FWDCX-D2C8J-H872K-2YT43";
                    case "Windows 10 Enterprise 2015 LTSB":
                        return "WNMTR-4C88C-JK8YV-HQ7T2-76DF9";
                    case "Windows 10 Enterprise 2016 LTSB":
                        return "DCPHK-NFMTC-H88MJ-PFHPY-QJ4BJ";


                    case "Windows Server 2016 Technical Preview 4 SERVERDATACENTER":
                        return "2KNJJ-33Y9H-2GXGX-KMQWH-G6H67";
                    case "Windows Server 2016 Technical Preview 4 SERVERDATACENTERCORE":
                        return "2KNJJ-33Y9H-2GXGX-KMQWH-G6H67";
                    case "Windows Server 2016 Technical Preview 4 SERVERSTANDARD":
                        return "2KNJJ-33Y9H-2GXGX-KMQWH-G6H67";
                    case "Windows Server 2016 Technical Preview 4 SERVERSTANDARDCORE":
                        return "2KNJJ-33Y9H-2GXGX-KMQWH-G6H67";

                    case "Windows Server 2016 Technical Preview 5 SERVERDATACENTER":
                        return "2KNJJ-33Y9H-2GXGX-KMQWH-G6H67";
                    case "Windows Server 2016 Technical Preview 5 SERVERDATACENTERCORE":
                        return "2KNJJ-33Y9H-2GXGX-KMQWH-G6H67";
                    case "Windows Server 2016 Technical Preview 5 SERVERSTANDARD":
                        return "2KNJJ-33Y9H-2GXGX-KMQWH-G6H67";
                    case "Windows Server 2016 Technical Preview 5 SERVERSTANDARDCORE":
                        return "2KNJJ-33Y9H-2GXGX-KMQWH-G6H67";

                    case "Windows Server 2016 SERVERSTANDARDCORE":
                        return "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY";
                    case "Windows Server 2016 SERVERSTANDARD":
                        return "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY";
                    case "Windows Server 2016 SERVERDATACENTERCORE":
                        return "CB7KF-BWN84-R7R2Y-793K2-8XDDG";
                    case "Windows Server 2016 SERVERDATACENTER":
                        return "CB7KF-BWN84-R7R2Y-793K2-8XDDG";

                    case "Windows Server 2016 SERVERSTANDARDNANO":
                        return "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY";
                    case "Windows Server 2016 SERVERDATACENTERNANO":
                        return "CB7KF-BWN84-R7R2Y-793K2-8XDDG";

                    default:
                        return string.Empty;
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

        public OperatingSystem()
        { }

        public OperatingSystem(string operatingSystemName)
        {
            this.operatingSystemName = operatingSystemName;
        }

        public OperatingSystem(string operatingSystemName, AutomatedLab.Version version)
            : this(operatingSystemName)
        {
            this.version = version;
        }

        public OperatingSystem(string operatingSystemName, string isoPath)
            : this(operatingSystemName)
        {
            this.isoPath = isoPath;
        }

        public OperatingSystem(string operatingSystemName, string isoPath, Version version)
            : this(operatingSystemName)
        {
            this.isoPath = isoPath;
            this.version = version;
        }

        public OperatingSystem(string operatingSystemName, string isoPath, Version version, string imageName)
            : this(operatingSystemName)
        {
            this.isoPath = isoPath;
            this.version = version;
            this.operatingSystemImageName = imageName;
        }

        public override string ToString()
        {
            return operatingSystemName;
        }

        public string OperatingSystemImageName
        {
            get { return operatingSystemImageName; }
            set { operatingSystemImageName = value; }
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
                var exp = @"(?:Windows Server )?(\d{4})(( )?R2)?|(?:Windows )?((\d){1,2}(\.\d)?)";

                var match = System.Text.RegularExpressions.Regex.Match(operatingSystemName, exp);

                if (!string.IsNullOrEmpty(match.Groups[1].Value))
                {
                    return match.Groups[1].Value;
                }
                else
                {
                    return match.Groups[4].Value;
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