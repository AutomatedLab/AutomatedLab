using System;
using System.Management.Automation;

namespace AutomatedLab
{
    [Serializable]
    public class SoftwarePackage
    {
        private string path;
        private string commandLine;
        private string processName;
        private int timeout;
        private ScriptBlock customProgressChecker;
        private bool copyFolder;

        public string Path
        {
            get { return path; }
            set { path = value; }
        }

        public string CommandLine
        {
            get { return commandLine; }
            set { commandLine = value; }
        }

        public string ProcessName
        {
            get { return processName; }
            set { processName = value; }
        }

        public int Timeout
        {
            get { return timeout; }
            set { timeout = value; }
        }

        public ScriptBlock CustomProgressChecker
        {
            get { return customProgressChecker; }
            set { customProgressChecker = value; }
        }

        public bool CopyFolder
        {
            get { return copyFolder; }
            set { copyFolder = value; }
        }

        public override string ToString()
        {
            return System.IO.Path.GetFileName(path);
        }
    }
}
