using System;

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

        public override string ToString()
        {
            return Offer;
        }
    }
}
