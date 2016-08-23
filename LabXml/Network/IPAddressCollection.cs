using System.Collections.Generic;
using System.Collections;
using System.Numerics;
using System;
using System.Net.Sockets;

/// <summary>
/// Code taken from https://github.com/lduchosal/ipnetwork on 2015 10 26
/// </summary>

namespace AutomatedLab
{
    public class IPAddressCollection : IEnumerable<IPAddress>, IEnumerator<IPAddress>
    {

        private IPNetwork _ipnetwork;
        private BigInteger _enumerator;

        internal IPAddressCollection(IPNetwork ipnetwork)
        {
            this._ipnetwork = ipnetwork;
            this._enumerator = -1;
        }


        #region Count, Array, Enumerator

        public BigInteger Count
        {
            get
            {
                return this._ipnetwork.Total;
            }
        }

        public IPAddress this[BigInteger i]
        {
            get
            {
                if (i >= this.Count)
                {
                    throw new ArgumentOutOfRangeException("i");
                }
                byte width = this._ipnetwork.AddressFamily == AddressFamily.InterNetwork ? (byte)32 : (byte)128;
                IPNetworkCollection ipn = IPNetwork.Subnet(this._ipnetwork, width);
                return ipn[i].Network;
            }
        }

        #endregion

        #region IEnumerable Members

        IEnumerator<IPAddress> IEnumerable<IPAddress>.GetEnumerator()
        {
            return this;
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return this;
        }

        #region IEnumerator<IPNetwork> Members

        public IPAddress Current
        {
            get { return this[this._enumerator]; }
        }

        #endregion

        #region IDisposable Members

        public void Dispose()
        {
            // nothing to dispose
            return;
        }

        #endregion

        #region IEnumerator Members

        object IEnumerator.Current
        {
            get { return this.Current; }
        }

        public bool MoveNext()
        {
            this._enumerator++;
            if (this._enumerator >= this.Count)
            {
                return false;
            }
            return true;

        }

        public void Reset()
        {
            this._enumerator = -1;
        }

        #endregion

        #endregion
    }
}