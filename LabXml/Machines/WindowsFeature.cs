namespace AutomatedLab
{
    public enum FeatureState
    {
        Installed,
        Available,
        Removed
    }

    public class WindowsFeature
    {
        public string Name { get; set; }

        public string ComputerName { get; set; }

        public string FeatureName
        {
            get { return Name; }
            set { FeatureName = value; }
        }

        public FeatureState State { get; set; }
    }
}
