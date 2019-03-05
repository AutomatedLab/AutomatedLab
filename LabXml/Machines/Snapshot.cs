using System;

namespace AutomatedLab
{
    /// <summary>
    /// Lowest common denominator of Azure and HyperV snapshots
    /// </summary>
    [Serializable]
    public class Snapshot
    {
        /// <summary>
        /// The name of the snapshot.
        /// </summary>
        public string SnapshotName { get; set; }

        /// <summary>
        /// Creation time of the snapshot.
        /// </summary>
        public DateTime CreationTime { get; set; }

        /// <summary>
        /// The name of the VM to which the snapshot belongs.
        /// </summary>
        public string ComputerName { get; set; }

        /// <summary>
        /// Instanciate a new empty Snapshot.
        /// </summary>
        public Snapshot()
        {

        }

        /// <summary>
        /// Instanciate a new Snapshot.
        /// </summary>
        /// <param name="snapshotName">The name of the snapshot.</param>
        /// <param name="creationTime">The creation time stamp.</param>
        public Snapshot(string snapshotName, string computerName, DateTime creationTime)
        {
            SnapshotName = snapshotName;
            ComputerName = computerName;
            CreationTime = creationTime;
        }

        public override string ToString()
        {
            return SnapshotName;
        }

        public string ToString(bool onAzure)
        {
            return string.Format("{0}_{1}", ComputerName, SnapshotName);
        }
    }
}
