using System;

namespace AutomatedLab
{
    [Obsolete("No longer used in V2. Member still defined due to compatibility.")]
    public enum MachineTypes
    {
        Unknown = 0,
        Server = 1,
        Client = 2
    }

    public enum VirtualizationHost
    {
        HyperV = 1,
        Azure = 2,
        VMWare = 3
    }

    [Flags]
    public enum Roles : long
    {
        RootDC = 1,
        FirstChildDC = 2,
        DC = 4,
        ADDS = RootDC | FirstChildDC | DC,
        FileServer = 8,
        WebServer = 16,
        DHCP = 32,
        Routing = 64,
        CaRoot = 128,
        CaSubordinate = 256,
        SQLServer2008 = 512,
        SQLServer2008R2 = 1024,
        SQLServer2012 = 2048,
        SQLServer2014 = 4096,
        SQLServer2016 = 8192,
        VisualStudio2013 = 16384,
        VisualStudio2015 = 32768,
        SharePoint2013 = 65536,
        SharePoint2016 = 131072,
        Orchestrator2012 = 262144,
        Exchange2013 = 524288,
        Exchange2016 = 1048576,
        Office2013 = 2097152,
        Office2016 = 4194304,
        ADFS = 8388608,
        ADFSWAP = 16777216,
        ADFSProxy = 33554432,
        DSCPullServer = 67108864
    }

    public enum ActiveDirectoryFunctionalLevel
    {
        Win2003 = 2,
        Win2008 = 3,
        Win2008R2 = 4,
        Win2012 = 5,
        Win2012R2 = 6
    }

    public enum SwitchType
    {
        Internal,
        External,
        Private
    }

    public enum NetBiosOptions
    {
        Default,
        Enabled,
        Disabled
    }

    [Flags]
    public enum LabVMInitState
    {
        Uninitialized = 0,
        ReachedByAutomatedLab = 1,
        EnabledCredSsp = 2,
        NetworkAdapterBindingCorrected = 4
    }
}