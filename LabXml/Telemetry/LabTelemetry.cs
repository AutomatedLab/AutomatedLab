using System;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;
using System.Collections.Generic;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using System.Linq;
using System.Diagnostics;

namespace AutomatedLab
{
    public class LabTelemetry
    {
        private static volatile LabTelemetry instance;
        private static object syncRoot = new Object();
        private TelemetryClient telemetryClient = null;
        private const string telemetryKey = "03367df3-a45f-4ba8-9163-e73999e2c7b6";
        private DateTime labStarted;
        private const string _telemetryOptInVar = "AUTOMATEDLAB_TELEMETRY_OPTIN";
        public bool TelemetryEnabled { get; private set; }

        private LabTelemetry()
        {
            TelemetryConfiguration.Active.InstrumentationKey = telemetryKey;
            TelemetryConfiguration.Active.TelemetryChannel.DeveloperMode = false;

            // Add our own initializer to filter out any personal information before sending telemetry data
            TelemetryConfiguration.Active.TelemetryInitializers.Add(new LabTelemetryInitializer());
            telemetryClient = new TelemetryClient();
            TelemetryEnabled = GetEnvironmentVariableAsBool(_telemetryOptInVar, false);

            // Initialize EventLog
            if (Environment.OSVersion.Platform == (PlatformID.Unix | PlatformID.MacOSX)) return;
            if (!EventLog.SourceExists("AutomatedLab")) EventLog.CreateEventSource("AutomatedLab", "Application");
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

        public void LabStarted(byte[] labData, string version, string osVersion, string psVersion)
        {
            if (!GetEnvironmentVariableAsBool(_telemetryOptInVar, false)) return;
            var lab = Lab.Import(labData);
            lab.Machines.ForEach(m => SendUsedRole(m.Roles.Select(r => r.Name.ToString()).ToList()));
            lab.Machines.ForEach(m => SendUsedRole(m.PostInstallationActivity.Where(p => p.IsCustomRole).Select(c => System.IO.Path.GetFileNameWithoutExtension(c.ScriptFileName)).ToList(), true));

            var properties = new Dictionary<string, string>
            {
                { "version", version},
                { "hypervisor", lab.DefaultVirtualizationEngine},
                { "osversion", osVersion},
                { "psversion", psVersion}
            };

            var metrics = new Dictionary<string, double>
            {
                {
                    "machineCount", lab.Machines.Count
                }
            };

            labStarted = DateTime.Now;

            var eventMessage = "Lab started - Transmitting the following:" +
                $"\r\nversion = {version}" +
                $"\r\nhypervisor = {lab.DefaultVirtualizationEngine}" +
                $"\r\nosversion = {osVersion}" +
                $"\r\npsversion = {psVersion}" +
                $"\r\nmachineCount = {lab.Machines.Count}";
            try
            {
                EventLog.WriteEntry("AutomatedLab", eventMessage, EventLogEntryType.Information, 101);
            }
            catch { }
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

        public void LabFinished(byte[] labData)
        {
            if (!GetEnvironmentVariableAsBool(_telemetryOptInVar, false)) return;
            var lab = Lab.Import(labData);

            var labDuration = DateTime.Now - labStarted;

            var properties = new Dictionary<string, string>
            {
                { "dayOfWeek", labStarted.DayOfWeek.ToString() }
            };

            var metrics = new Dictionary<string, double>
            {
                { "timeTakenSeconds", labDuration.TotalSeconds }
            };

            var eventMessage = "Lab finished - Transmitting the following:" +
                            $"\r\ndayOfWeek = {labStarted.DayOfWeek.ToString()}" +
                            $"\r\ntimeTakenSeconds = {labDuration.TotalSeconds}";
            try
            {
                EventLog.WriteEntry("AutomatedLab", eventMessage, EventLogEntryType.Information, 102);
            }
            catch { }
            try
            {
                telemetryClient.TrackEvent("LabFinished", properties, metrics);
                telemetryClient.Flush();
            }
            catch
            {
                ; //nothing to catch. If it doesn't work, it doesn't work.
            }
        }

        public void LabRemoved(byte[] labData)
        {
            if (!GetEnvironmentVariableAsBool(_telemetryOptInVar, false)) return;
            var lab = Lab.Import(labData);
            var f = new System.IO.FileInfo(lab.LabFilePath);
            var duration = DateTime.Now - f.CreationTime;

            var metrics = new Dictionary<string, double>
            {
                { "labRunningTicks", duration.Ticks }
            };

            var eventMessage = "Lab removed - Transmitting the following:" +
                            $"\r\nlabRunningTicks = {duration.Ticks}";
            try
            {
                EventLog.WriteEntry("AutomatedLab", eventMessage, EventLogEntryType.Information, 103);
            }
            catch { }

            try
            {
                telemetryClient.TrackEvent("LabRemoved", null, metrics);
                telemetryClient.Flush();
            }
            catch
            {
                ; //nothing to catch. If it doesn't work, it doesn't work.
            }
        }

        public void FunctionCalled(string functionName)
        {
            if (!GetEnvironmentVariableAsBool(_telemetryOptInVar, false)) return;

            var properties = new Dictionary<string, string>
            {
                { "functionname", functionName}
            };

            var eventMessage = "Function called - Transmitting the following:" +
                $"\r\nfunction = {functionName}";
            try
            {
                EventLog.WriteEntry("AutomatedLab", eventMessage, EventLogEntryType.Information, 101);
            }
            catch { }

            try
            {
                telemetryClient.TrackEvent("FunctionCalled", properties);
                telemetryClient.Flush();
            }
            catch
            {
                ; //nothing to catch. If it doesn't work, it doesn't work.
            }
        }

        private void SendUsedRole(List<string> roleName, bool isCustomRole = false)
        {
            if (!GetEnvironmentVariableAsBool(_telemetryOptInVar, false)) return;
            var eventMessage = "Sending role infos - Transmitting the following:";

            roleName.ForEach(name =>
            {
                eventMessage += $"\r\nrole: {name}";
                var properties = new Dictionary<string, string>
                {
                    { "role", name},
                };

                try
                {
                    var telemetryType = isCustomRole ? "CustomRole" : "Role";
                    telemetryClient.TrackEvent(telemetryType, properties, null);
                }
                catch
                {
                    ; //nothing to catch. If it doesn't work, it doesn't work.
                }
            });

            try
            {
                EventLog.WriteEntry("AutomatedLab", eventMessage, EventLogEntryType.Information, 104);
            }
            catch { }
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

    public class LabTelemetryInitializer : ITelemetryInitializer
    {
        public void Initialize(ITelemetry telemetry)
        {
            var requestTelemetry = telemetry as EventTelemetry;
            // Is this a TrackRequest() ?
            if (requestTelemetry == null) return;

            // Strip personally identifiable info from request
            requestTelemetry.Context.Cloud.RoleInstance = "nope";
            requestTelemetry.Context.Cloud.RoleName = "nope";
        }
    }
}
