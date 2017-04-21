using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml;

namespace AutomatedLab
{

    public class PathValidator : XmlValidator, IValidate
    {
        public PathValidator()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var pathsNotFound = new List<string>();

            foreach (var doc in docs)
            {
                var paths = doc.SelectNodes("//Path").OfType<XmlElement>().Select(e => e.InnerText);

                foreach (var path in paths)
                {
                    if (path.StartsWith("http"))
                    {
                        yield return new ValidationMessage()
                        {
                            Message = "URI skipped",
                            TargetObject = path,
                            Type = MessageType.Verbose
                        };

                        continue;
                    }

                    if (!File.Exists(path) & !Directory.Exists(path))
                    {
                        yield return new ValidationMessage()
                        {
                            Message = "The path could not be found",
                            TargetObject = path,
                            Type = MessageType.Error
                        };
                    }
                    else
                    {
                        yield return new ValidationMessage()
                        {
                            Message = "Path verified successfully",
                            TargetObject = path,
                            Type = MessageType.Verbose
                        };
                    }
                }
            }
        }
    }
}
