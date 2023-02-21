using System;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;
using System.Collections.Generic;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using System.Linq;
using System.Diagnostics;
using Microsoft.ApplicationInsights.Extensibility.Implementation.Tracing;

namespace AutomatedLab
{
    public class LabTelemetry
    {
        private static volatile LabTelemetry instance;
        private static object syncRoot = new Object();
        private TelemetryClient telemetryClient = null;
        private const string telemetryConnectionString = "InstrumentationKey=fbff0c1a-4f7b-4b90-b74d-8370a38fd213;IngestionEndpoint=https://westeurope-5.in.applicationinsights.azure.com/;LiveEndpoint=https://westeurope.livediagnostics.monitor.azure.com/";
        private DateTime labStarted;
        private const string _telemetryOptInVar = "AUTOMATEDLAB_TELEMETRY_OPTIN";
        private const string _nixLogPath = "/var/log/automatedlab/telemetry.log";
        public bool TelemetryEnabled { get; private set; }

        private LabTelemetry()
        {
            var config = TelemetryConfiguration.CreateDefault();
            config.ConnectionString = telemetryConnectionString;
            config.TelemetryChannel.DeveloperMode = false;
            config.TelemetryInitializers.Add(new LabTelemetryInitializer());

            var diagnosticsTelemetryModule = new DiagnosticsTelemetryModule();
            diagnosticsTelemetryModule.IsHeartbeatEnabled = false;
            diagnosticsTelemetryModule.Initialize(config);
            if (null == telemetryClient)
            {
                telemetryClient = new TelemetryClient(config);
            }

            TelemetryEnabled = GetEnvironmentVariableAsBool(_telemetryOptInVar, false);

            // Initialize EventLog
            if (Environment.OSVersion.Platform == PlatformID.Unix || Environment.OSVersion.Platform == PlatformID.MacOSX) return;
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

        private void WriteTelemetryEvent(string message, int id)
        {
            // Separate method in case we find a reliable way to log on Linux
            if (Environment.OSVersion.Platform == PlatformID.Unix || Environment.OSVersion.Platform == PlatformID.MacOSX)
            {
                try
                {
                    System.IO.File.AppendAllText(_nixLogPath, $"{DateTime.Now.ToString("u")}<{id}>{message}");
                }
                catch { }

            }

            if (Environment.OSVersion.Platform.Equals(PlatformID.Win32NT))
            {
                try
                {
                    EventLog.WriteEntry("AutomatedLab", message, EventLogEntryType.Information, id);
                }
                catch { }
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
            WriteTelemetryEvent(eventMessage, 101);

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
            WriteTelemetryEvent(eventMessage, 102);

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
            WriteTelemetryEvent(eventMessage, 103);

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
            WriteTelemetryEvent(eventMessage, 105);

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
            if (roleName.Count == 0) return;
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

            WriteTelemetryEvent(eventMessage, 104);
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
