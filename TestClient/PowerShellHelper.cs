using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Threading.Tasks;

namespace TestClient
{
    public class PowerShellHelper : IDisposable
    {
        Runspace runspace;
        
        public PowerShellHelper()
        {
            runspace = RunspaceFactory.CreateRunspace();
            runspace.Open();
        }

        public List<PSObject> InvokeScript(string script)
        {
            var powershell = PowerShell.Create();
            powershell.Runspace = runspace;

            powershell.Commands.AddScript(script);
            var result = powershell.Invoke();

            powershell.Dispose();

            return result.ToList();
        }

        public List<PSObject> InvokeCommand(string command)
        {
            var parameters = new Dictionary<string, object>();

            return InvokeCommand(command, parameters);
        }

        public List<PSObject> InvokeCommand(string command, Dictionary<string, object> parameters)
        {
            var runspace = RunspaceFactory.CreateRunspace();
            runspace.Open();

            var result = InvokeCommand(command, parameters, runspace);

            runspace.Close();

            return result;
        }

        public List<PSObject> InvokeCommand(string command, Dictionary<string, object> parameters, Runspace runspace)
        {            
            var powershell = PowerShell.Create();
            powershell.Runspace = runspace;

            var cmd = new Command(command);
            foreach (var parameter in parameters)
            {
                cmd.Parameters.Add(parameter.Key, parameter.Value);
            }

            powershell.Commands.AddCommand(cmd);
            var result = powershell.Invoke();

            powershell.Dispose();

            return result.ToList();
        }

        #region IDisposable Support
        private bool disposedValue = false; // To detect redundant calls

        protected virtual void Dispose(bool disposing)
        {
            if (!disposedValue)
            {
                if (disposing)
                {
                    runspace.Close();
                    runspace.Dispose();
                }

                disposedValue = true;
            }
        }
        
        public void Dispose()
        {
            Dispose(true);
        }
        #endregion
    }
}
