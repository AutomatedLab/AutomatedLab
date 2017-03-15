namespace AutomatedLab
{
    public class Disk
    {
        private string path;
        private string name;
        private int diskSize;
        public bool SkipInitialization { get; set; }

        public string Path
        {
            get { return path; }
            set { path = value; }
        }

        public string Name
        {
            get { return name; }
            set { name = value; }
        }

        public int DiskSize
        {
            get { return diskSize; }
            set { diskSize = value; }
        }

        public string FileName
        {
            get
            {
                return System.IO.Path.GetFileName(path);
            }
        }

        public override string ToString()
        {
            return FileName;
        }
    }
}
