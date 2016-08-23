using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Reflection;
using AutomatedLab;
using LabXml;

namespace TestClient
{

    class Program
    {
        static void Main(string[] args)
        {
            //SerializationTest1();

            var labPath = @"C:\Users\randr\Documents\AutomatedLab-Labs\SingleMachine\Lab.xml";
            var ltest1 = XmlStore<Lab>.Import(labPath);
            var machines2 = ListXmlStore<Machine>.Import(labPath.Replace("Lab.xml", "Machines.xml"));

            var x2 = machines2.SelectMany(m => m.NetworkAdapters).Select(na => na.Ipv4DnsServers);

            XmlValidatorArgs.XmlPath = labPath;
            LabValidatorArgs.XmlPath = labPath;

            var summaryMessageContainer = new ValidationMessageContainer();

            var a = Assembly.GetAssembly(typeof(ValidatorBase));
            foreach (Type t in a.GetTypes())
            {
                if (t.IsSubclassOf(typeof(ValidatorBase)))
                {
                    var validator = (ValidatorBase)Activator.CreateInstance(t);
                    summaryMessageContainer += validator.MessageContainer;

                    Console.WriteLine(t);
                }
            }

            summaryMessageContainer.AddSummary();
            var dasda = summaryMessageContainer.GetFilteredMessages();

            Console.ReadKey();

            var isov = new PathValidator();

            //var messages2 = isov.Validate().ToList();
            var labsDirectory = new DirectoryInfo(@"C:\Users\randr\Documents\AutomatedLab-Labs");
            var sampleScriptDirectory = new DirectoryInfo(@"C:\Users\randr\Documents\AutomatedLab Sample Scripts");
            var sampleScriptFiles = sampleScriptDirectory.EnumerateFiles("*.ps1", SearchOption.AllDirectories);

            foreach (var file in sampleScriptFiles)
            {
                var id = Guid.NewGuid();
                IEnumerable<ErrorRecord> errors;
                var scriptContent = File.ReadAllText(file.FullName)
                    .Replace("Install-Lab", "Export-LabDefinition");

                var labNameStart = scriptContent.IndexOf("'") + 1;
                var labNameEnd = scriptContent.IndexOf("'", labNameStart);
                scriptContent = scriptContent.Remove(labNameStart, labNameEnd - labNameStart);
                scriptContent = scriptContent.Insert(labNameStart, id.ToString());

                try
                {
                    var result = PowerShellHelper.InvokeCommand(scriptContent, out errors);

                    var labXmlPath = System.IO.Path.Combine(labsDirectory.FullName, id.ToString(), "Lab.xml");
                    var labPaths = new List<string>() { System.IO.Path.Combine(labsDirectory.FullName, id.ToString(), "Machines.xml") };



                }
                catch (Exception ex)
                {
                    Console.WriteLine(ex.Message);
                }
            }

            Console.ReadKey();

            SerializationTest1();
            var l1 = XmlStore<Lab>.Import(@"D:\POSH\Lab.xml");
            //var l1 = XmlStore<Lab>.Import(@"C:\Users\randr_000\Documents\AutomatedLab-Labs\Small1\Lab.xml");

            //var w2012r2 = new AutomatedLab.OperatingSystem("Windows Server 2012 R2 SERVERDATACENTER");
            //var w2012 = new AutomatedLab.OperatingSystem("Windows Server 2012 SERVERDATACENTER");
            //var w2008r2 = new AutomatedLab.OperatingSystem("Windows Server 2008 R2 SERVERSTANDARD");
            //var w2008 = new AutomatedLab.OperatingSystem("Windows Server 2008 SERVERSTANDARD");
            //var w10 = new AutomatedLab.OperatingSystem("Windows Technical Preview");
            //var w7 = new AutomatedLab.OperatingSystem("Windows 7 ENTERPRISE");
            //var w8 = new AutomatedLab.OperatingSystem("Windows 8 Pro");
            //var w81 = new AutomatedLab.OperatingSystem("Windows 8.1 Pro");

            //var w2012r2 = new AutomatedLab.OperatingSystem("2012 R2");
            //var w2012 = new AutomatedLab.OperatingSystem("2012");
            //var w2008r2 = new AutomatedLab.OperatingSystem("2008 R2 SERVERSTANDARD");
            //var w2008 = new AutomatedLab.OperatingSystem("Windows Server 2008 SERVERSTANDARD");
            //var w10 = new AutomatedLab.OperatingSystem("Windows Technical Preview");
            var w7 = new AutomatedLab.OperatingSystem("Windows 7 ENTERPRISE");
            var w8 = new AutomatedLab.OperatingSystem("Windows 8 Pro");
            var w81 = new AutomatedLab.OperatingSystem("Windows 8.1 Pro");
            //var xx1 = w2012.Version;
            var xx2 = w7.Version;

            var ll = new Lab();

            var labPath2 = @"C:\Users\randr_000\Documents\AutomatedLab-Labs\POSH";
            var paths = new List<string>() { string.Format(@"{0}\Machines.xml", labPath2) };
            //AutomatedLab.LabXmlValidator lv = new AutomatedLab.LabXmlValidator(string.Format(@"{0}\Lab.xml", labPath2), paths.ToArray());
            //lv.RunTests();

            //var results = lv.GetMessages().ToList();

            var lab = Lab.Import(System.IO.Path.Combine(labPath2, "Lab.xml"));
            var machines = ListXmlStore<Machine>.Import(System.IO.Path.Combine(labPath2, "Machines.xml"));

            var m1 = machines.Where(m => m.Name == "xAZDC1").FirstOrDefault();
            var c1 = m1.GetLocalCredential();

            var x = 5;
        }

        public static void SerializationTest1()
        {
            var m = new Machine();
            m.Memory = 1024;
            m.Name = "Test2";
            //m.Network = "lab";
            //m.IpAddress = "192.168.10.10";
            //m.Gateway = "192.168.10.1";
            m.DiskSize = 60;
            //m.DNSServers.Add("192.168.10.10");
            //m.DNSServers.Add("192.168.10.11");
            m.HostType = VirtualizationHost.HyperV;
            m.IsDomainJoined = false;
            m.UnattendedXml = "unattended.xml";
            m.OperatingSystem = new AutomatedLab.OperatingSystem("Windows Server 2012 R2 SERVERDATACENTER", "E:\\", (AutomatedLab.Version)"6.4.12.0");
            m.InstallationUser = new User("Administrator", "Password1");
            m.DomainName = "vm.net";
            m.HostType = VirtualizationHost.HyperV;
            m.PostInstallationActivity.Add(
                new PostInstallationActivity()
                {
                    DependencyFolder = new AutomatedLab.Path() { Value = @"c:\test" },
                    IsoImage = new AutomatedLab.Path() { Value = @"c:\test\windows.iso" },
                    ScriptFileName = "SomeScript.ps1"
                });

            m.Roles.Add(new Role()
            {
                Name = Roles.RootDC,
                Properties = new SerializableDictionary<string, string>() { {"DBServer", "Server1"},
                    {"DBName","Orch"}}

            });
            var h = new System.Collections.Hashtable() { { "DBServer", "Server1" }, { "DBName", "Orch" } };
            var h1 = (SerializableDictionary<string, string>)h;


            var machines = new ListXmlStore<Machine>();
            //machines.Add(m);
            //machines.Add(m);
            machines.Add(m);
            machines.Timestamp = DateTime.Now;
            machines.Metadata = new List<string>() { "Somedata", "sdafds" };
            machines.ID = Guid.NewGuid();

            machines.Export("d:\\x.xml");

            var lab = new AutomatedLab.Lab();

            lab.Domains = new List<Domain>() {
                new Domain { Name = "vm.net", Administrator = new User("Administrator", "Password1") },
                new Domain { Name = "a.vm.net", Administrator = new User() { UserName = "Administrator", Password = "Password1" } },
                new Domain { Name = "b.vm.net", Administrator = new User() { UserName = "Administrator", Password = "Password1" } }
            };

            lab.MachineDefinitionFiles = new List<MachineDefinitionFile>() {
                new MachineDefinitionFile() { Path = @"D:\LabTest\DomainControllers.xml"},
                new MachineDefinitionFile() { Path = @"D:\LabTest\MemberServers.xml"}
            };

            lab.VirtualNetworks = new List<VirtualNetwork>() {
                new VirtualNetwork() { Name = "Lab", AddressSpace  = "192.168.10.1/24", HostType = VirtualizationHost.HyperV},
                new VirtualNetwork() { Name = "Test",  AddressSpace = "10.0.0.1/8", HostType = VirtualizationHost.HyperV}
            };

            lab.Sources.ISOs = new ListXmlStore<IsoImage>(){
                new IsoImage() {
                    Name = "Server",
                    Path = @"E:\LabConfig\ISOs\en_windows_server_2012_x64_dvd_915478.iso",
                    ReferenceDisk = "WindowsServer2012Base.vhdx",
                    ImageType = MachineTypes.Server
                },
                new IsoImage() {
                    Name = "Client",
                    Path = @"E:\LabConfig\ISOs\en_windows_8_x64_dvd_915440.iso",
                    ReferenceDisk = "Windows8Base.vhdx",
                    ImageType = MachineTypes.Client,
                },
                new IsoImage(){
                    Name = "SQL",
                    Path = @"E:\LabConfig\ISOs\en_sql_server_2008_r2_enterprise_x86_x64_ia64_dvd_520517.iso"
                },
                new IsoImage(){
                    Name = "Exchange",
                    Path = @"E:\LabConfig\ISOs\mu_exchange_server_2013_with_sp1_x64_dvd_4059293.iso"
                },
                new IsoImage(){
                    Name = "SQL",
                    Path = @"E:\LabConfig\ISOs\en_visual_studio_ultimate_2012_x86_dvd_920947.iso"
                }
            };

            lab.Sources.UnattendedXml = new AutomatedLab.Path() { Value = @"D:\LabConfig\Unattended" };

            lab.Target.Path = @"D:\LabVMs";
            lab.Target.ReferenceDiskSizeInGB = 60;

            lab.Export("d:\\lab.xml");

            var lab1 = Lab.Import("d:\\lab.xml");
            lab1.Machines = ListXmlStore<Machine>.Import("d:\\x.xml");
            lab1.GetParentDomain("vm.net");

            var os = lab.Sources.ISOs.OfType<IsoImage>();
        }

        void old()
        {
            //machines.ExportToRegistry("Stores", "OperatingSystems");

            //var machines2 = (ListXmlStore<Machine>)ListXmlStore<Machine>.Import(@"d:\\x.xml");
            //var machinesFromReg = (ListXmlStore<Machine>)ListXmlStore<Machine>.ImportFromRegistry("Stores", "OperatingSystems");

            var m = new Machine();
            m.Memory = 1024;
            m.Name = "Test2";
            //m.Network = "lab";
            //m.IpAddress = "192.168.10.10";
            //m.Gateway = "192.168.10.1";
            m.DiskSize = 60;
            //m.DNSServers.Add("192.168.10.10");
            //m.DNSServers.Add("192.168.10.11");
            m.HostType = VirtualizationHost.HyperV;

            var dic = new DictionaryXmlStore<string, Machine>();
            dic.Add("ID1", m);
            dic.Add("ID2", m);
            dic.Add("ID3", m);
            dic.Timestamp = DateTime.Now;
            dic.ID = Guid.NewGuid();
            dic.Metadata.Add("Info1");
            dic.Metadata.Add(Convert.ToString(4534584035830948));
            //dic.Export("d:\\y.xml");
            //dic.ExportToRegistry("Cache", "Test1");

            var dicReg = ListXmlStore<AutomatedLab.OperatingSystem>.ImportFromRegistry("Cache", "LocalOperatingSystems");
            var dic2 = DictionaryXmlStore<string, Machine>.Import("d:\\y.xml");

            //machines = (ListXmlStore<Machine>)ListXmlStore<Machine>.Import(@"D:\LabTest\MemberServers.xml");
            //machines.AddFromFile(@"D:\LabTest\DomainControllers.xml");
            //machines.Export("d:\\x.xml");

            //var lab = (XmlStore<Lab>)XmlStore<Lab>.Import(@"D:\LabConfig\Definitions.xml");
        }
    }
}