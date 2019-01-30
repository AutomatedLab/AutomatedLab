namespace AutomatedLab
{
    public class Disk
    {
        public bool SkipInitialization { get; set; }

        public string Path { get; set; }

        public string Name { get; set; }

        public int DiskSize { get; set; }

        public long AllocationUnitSize { get; set; }
        
        public bool UseLargeFRS { get; set; }

        public string Label { get; set; }

        public char DriveLetter { get; set; }

        public string FileName
        {
            get
            {
                return System.IO.Path.GetFileName(Path);
            }
        }

        public override string ToString()
        {
            return Name;
        }
    }
}
