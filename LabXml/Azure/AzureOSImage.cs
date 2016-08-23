using System;
using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureOSImage : CopiedObject<AzureOSImage>
    {
        public string ImageName { get; set; }

        public string OS { get; set; }

        public string MediaLink { get; set; }

        public int? LogicalSizeInGB { get; set; }

        public string AffinityGroup { get; set; }

        public string Category { get; set; }

        public string Location { get; set; }

        public string Label { get; set; }

        public string Description { get; set; }

        public string Eula { get; set; }

        public string ImageFamily { get; set; }

        public DateTime? PublishedDate { get; set; }

        public bool? IsPremium { get; set; }

        public string IconUri { get; set; }

        public string SmallIconUri { get; set; }

        public string PrivacyUri { get; set; }

        public string RecommendedVMSize { get; set; }

        public string PublisherName { get; set; }

        public string IOType { get; set; }

        public bool? ShowInGui { get; set; }

        public string IconName { get; set; }

        public string SmallIconName { get; set; }

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
            return ImageName;
        }
    }
}
