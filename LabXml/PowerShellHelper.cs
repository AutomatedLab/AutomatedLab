using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;

namespace LabXml
{
    public static class PowerShellHelper
    {
        static Runspace runspace = null;
        static PowerShell ps = null;
        static PowerShellHelper()
        {
            runspace = RunspaceFactory.CreateRunspace();
            runspace.Open();

            ps = PowerShell.Create();
        }
        public static IEnumerable<PSObject> InvokeCommand(string script)
        {
            ps.AddScript(script);

            var result = ps.Invoke();

            return result;
        }

        public static IEnumerable<PSObject> InvokeCommand(string script, out IEnumerable<ErrorRecord> errors)
        {
            errors = new List<ErrorRecord>();

            ps.AddScript(script);

            var result = ps.Invoke();
            errors = ps.Streams.Error.ToList();

            return result;
        }

        public static IEnumerable<PSObject> InvokeScript(string path, out IEnumerable<ErrorRecord> errors)
        {
            errors = new List<ErrorRecord>();

            var script = System.IO.File.ReadAllText(path);

            var powershell = PowerShell.Create();
            powershell.Runspace = runspace;

            powershell.AddScript(script);
            
            var results = powershell.Invoke();
            errors = ps.Streams.Error.ToList();

            return results;
        }

        public static IEnumerable<T> InvokeCommand<T>(string script)
        {
            ps.AddScript(script);

            var result = ps.Invoke();

            return result.Cast<T>();
        }
    }
}