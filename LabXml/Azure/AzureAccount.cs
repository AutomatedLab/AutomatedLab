using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    public class AzureAccount : CopiedObject<AzureAccount>
    {
        public string Id { get; set; }
        public SerializableDictionary<int, string> Properties { get; set; }
        public int Type { get; set; }

        public AzureAccount()
        { }

        public static AzureAccount Create(object input)
        {
            return Create<AzureAccount>(input);
        }

        public static IEnumerable<AzureAccount> Create(object[] input)
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create<AzureAccount>(item);
                }
            }
            else
            {
                yield break;
            }
        }

        public override string ToString()
        {
            return Id;
        }
    }
}
