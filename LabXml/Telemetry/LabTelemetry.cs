﻿using System;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;
using System.Collections.Generic;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;

namespace AutomatedLab
{
    public class LabTelemetry
    {
        private static volatile LabTelemetry instance;
        private static object syncRoot = new Object();
        private TelemetryClient telemetryClient = null;
        private const string telemetryKey = "03367df3-a45f-4ba8-9163-e73999e2c7b6";
        private DateTime labStarted;
        private const string _telemetryOptoutEnvVar = "AUTOMATEDLAB_TELEMETRY_OPTOUT";
        public bool TelemetryEnabled { get; private set; }

        private LabTelemetry()
        {
            TelemetryConfiguration.Active.InstrumentationKey = telemetryKey;
            TelemetryConfiguration.Active.TelemetryChannel.DeveloperMode = false;

            // Add our own initializer to filter out any personal information before sending telemetry data
            TelemetryConfiguration.Active.TelemetryInitializers.Add(new LabTelemetryInitializer());
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
        
        public void LabStarted(byte[] labData, string version, string osVersion, string psVersion)
        {
            if (GetEnvironmentVariableAsBool(_telemetryOptoutEnvVar, false)) return;
            var lab = Lab.Import(labData);

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
            if (GetEnvironmentVariableAsBool(_telemetryOptoutEnvVar, false)) return;
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
            if (GetEnvironmentVariableAsBool(_telemetryOptoutEnvVar, false)) return;

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
