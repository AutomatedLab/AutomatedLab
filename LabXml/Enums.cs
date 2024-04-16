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

    public enum PartitionStyle
    {
        MBR,
        GPT
    }

    public enum VirtualizationHost
    {
        HyperV = 1,
        Azure = 2,
        VMWare = 3
    }

    public enum OperatingSystemType
    {
        Windows,
        Linux
    }

    public enum LinuxType
    {
        Unknown,
        RedHat,
        SuSE,
        Ubuntu
    }

    [Flags]
    public enum Roles : ulong
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
        SQLServer2017 = 524288,
        SQLServer2019 = 67108864,
        DSCPullServer = 1048576,
        Office2013 = 2097152,
        Office2016 = 4194304,
        ADFS = 8388608,
        ADFSWAP = 16777216,
        ADFSProxy = 33554432,
        FailoverStorage = 134217728,
        FailoverNode = 268435456,
        Tfs2015 = 1073741824,
        Tfs2017 = 2147483648,
        TfsBuildWorker = 4294967296,
        Tfs2018 = 8589934592,
        SQLServer = SQLServer2008 | SQLServer2008R2 | SQLServer2012 | SQLServer2014 | SQLServer2016 | SQLServer2017 | SQLServer2019 | SQLServer2022,
        HyperV = 17179869184,
        AzDevOps = 34359738368,
        SharePoint2019 = 68719476736,
        SharePoint = SharePoint2013 | SharePoint2016 | SharePoint2019,
        WindowsAdminCenter = 137438953472,
        Scvmm2016 = 274877906944,
        Scvmm2019 = 549755813888,
        SCVMM = Scvmm2016 | Scvmm2019 | Scvmm2022,
        ScomManagement = 1099511627776,
        ScomConsole = 2199023255552,
        ScomWebConsole = 4398046511104,
        ScomReporting = 8796093022208,
        ScomGateway = 17592186044416,
        SCOM = ScomManagement | ScomConsole | ScomWebConsole | ScomReporting | ScomGateway,

        DynamicsFull = 35184372088832,
        DynamicsFrontend = 70368744177664,
        DynamicsBackend = 140737488355328,
        DynamicsAdmin = 281474976710656,
        Dynamics = DynamicsFull | DynamicsFrontend | DynamicsBackend | DynamicsAdmin,
        RemoteDesktopGateway = 562949953421312,
        RemoteDesktopWebAccess = 1125899906842624,
        RemoteDesktopSessionHost = 2251799813685248,
        RemoteDesktopConnectionBroker = 4503599627370496,
        RemoteDesktopLicensing = 9007199254740992,
        RemoteDesktopVirtualizationHost = 18014398509481984,
        RDS = RemoteDesktopConnectionBroker | RemoteDesktopGateway | RemoteDesktopLicensing | RemoteDesktopSessionHost | RemoteDesktopVirtualizationHost | RemoteDesktopWebAccess,
        ConfigurationManager = 36028797018963968,
        Scvmm2022 = 72057594037927936,
        SQLServer2022 = 144115188075855872
    }

    public enum ActiveDirectoryFunctionalLevel
    {
        Win2003 = 2,
        Win2008 = 3,
        Win2008R2 = 4,
        Win2012 = 5,
        Win2012R2 = 6,
        WinThreshold = 7,
        Win2025 = 10
    }

    public enum SwitchType
    {
        Internal = 1,
        External = 2,
        Private = 3
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

    public enum Architecture
    {
        x86 = 0, // Map DISM output
        x64 = 9, // Map DISM output
        Unknown
    }
}