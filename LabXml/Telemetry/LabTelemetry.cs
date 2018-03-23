using System;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;
using System.Collections.Generic;
using System.Xml;
using System.Linq;

namespace AutomatedLab
{
    public class LabTelemetry
    {
        private static volatile LabTelemetry instance;
        private static object syncRoot = new Object();
        private TelemetryClient telemetryClient = null;
        private const string telemetryKey = "03367df3-a45f-4ba8-9163-e73999e2c7b6";
        private List<XmlDocument> docs = new List<XmlDocument>();
        private Lab lab;
        private ListXmlStore<Machine> machines = new ListXmlStore<Machine>();
        private DateTime labStarted;
        private const string _telemetryOptoutEnvVar = "AUTOMATEDLAB_TELEMETRY_OPTOUT";
        public bool TelemetryEnabled { get; private set; }
        public string LabXmlPath { get; set; }

        private LabTelemetry()
        {
            TelemetryConfiguration.Active.InstrumentationKey = telemetryKey;
            TelemetryConfiguration.Active.TelemetryChannel.DeveloperMode = false;
            telemetryClient = new TelemetryClient();
            TelemetryEnabled = !GetEnvironmentVariableAsBool(_telemetryOptoutEnvVar, false);
        }

        // taken from https://github.com/powershell/powershell
        private static bool GetEnvironmentVariableAsBool(string name, bool defaultValue)
        {
            var str = Environment.GetEnvironmentVariable(name);
            if (string.IsNullOrEmpty(str))
            {
                return defaultValue;
            }

            switch (str.ToLowerInvariant())
            {
                case "true":
                case "1":
                case "yes":
                    return true;
                case "false":
                case "0":
                case "no":
                    return false;
                default:
                    return defaultValue;
            }
        }

        public static LabTelemetry Instance
        {
            get
            {
                if (instance == null)
                {
                    lock (syncRoot)
                    {
                        if (instance == null)
                            instance = new LabTelemetry();
                    }
                }

                return instance;
            }
        }

        private void ImportLabData()
        {
            if (string.IsNullOrWhiteSpace(LabXmlPath)) return;

            XmlDocument mainDoc = new XmlDocument();
            mainDoc.Load(LabXmlPath);
            docs.Add(mainDoc);

            var xmlPaths = mainDoc.SelectNodes("//@Path").OfType<XmlAttribute>().Select(e => e.Value).Where(text => text.EndsWith(".xml"));

            foreach (var path in xmlPaths)
            {
                XmlDocument doc = new XmlDocument();
                doc.Load(path);
                docs.Add(doc);
            }

            lab = Lab.Import(LabXmlPath);
            lab.MachineDefinitionFiles.ForEach(file => machines.AddFromFile(file.Path));
            machines.ForEach(m => SendUsedRole(m.Roles.Select(r => r.ToString()).ToList()));
            lab.Machines = machines;
        }

        public void LabStarted(string version, string osVersion)
        {
            if (string.IsNullOrWhiteSpace(LabXmlPath)) return;
            if (lab == null) ImportLabData();

            var properties = new Dictionary<string, string>
            {
                { "version", version},
                { "hypervisor", lab.DefaultVirtualizationEngine},
                { "osversion", osVersion}
            };

            var metrics = new Dictionary<string, double>
            {
                {
                    "machineCount", machines.Count
                }
            };

            labStarted = DateTime.Now;

            try
            {
                telemetryClient.TrackEvent("LabStarted", properties, metrics);
                telemetryClient.Flush();
            }
            catch
            {
                ; //nothing to catch. If it doesn't work, it doesn't work.
            }
        }

        public void LabFinished()
        {
            if (string.IsNullOrWhiteSpace(LabXmlPath)) return;
            if (lab == null) ImportLabData();

            var labDuration = DateTime.Now - labStarted;

            var properties = new Dictionary<string, string>
            {
                { "dayOfWeek", labStarted.DayOfWeek.ToString() }
            };

            var metrics = new Dictionary<string, double>
            {
                { "timeTakenSeconds", labDuration.TotalSeconds }
            };

            try
            {
                telemetryClient.TrackEvent("LabFinished", null, metrics);
                telemetryClient.Flush();
            }
            catch
            {
                ; //nothing to catch. If it doesn't work, it doesn't work.
            }
        }

        private void SendUsedRole(List<string> roleName)
        {
            if (string.IsNullOrWhiteSpace(LabXmlPath)) return;
            if (lab == null) ImportLabData();

            roleName.ForEach(name =>
            {
                var properties = new Dictionary<string, string>
                {
                    { "role", name},
                };

                try
                {
                    telemetryClient.TrackEvent("Role", properties, null);
                }
                catch
                {
                    ; //nothing to catch. If it doesn't work, it doesn't work.
                }
            });

            try
            {

                telemetryClient.Flush();
            }
            catch
            {
                ; //nothing to catch. If it doesn't work, it doesn't work.
            }
        }
    }
}
