using System;
using System.Runtime.InteropServices;

namespace AutomatedLab
{
    public class DiskSpaceWin32
    {
        [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Auto)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetDiskFreeSpaceEx(string lpDirectoryName,
           out ulong lpFreeBytesAvailable,
           out ulong lpTotalNumberOfBytes,
           out ulong lpTotalNumberOfFreeBytes);
    }
}