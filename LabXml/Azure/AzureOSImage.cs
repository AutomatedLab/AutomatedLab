using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureOSImage : CopiedObject<AzureOSImage>
    {
        public string Id { get; set; }
        public string Location { get; set; }
        public string Offer { get; set; }
        public string PublisherName { get; set; }
        public string Skus { get; set; }
        public string Version { get; set; }

        public AzureOSImage()
        { }

        public static AzureOSImage Create(object input)
        {
            return Create<AzureOSImage>(input);
        }

        public static IEnumerable<AzureOSImage> Create(object[] input)
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create<AzureOSImage>(item);
                }
            }
            else
            {
                yield break;
            }
        }

        public override string ToString()
        {
            return Offer;
        }
    }
}
