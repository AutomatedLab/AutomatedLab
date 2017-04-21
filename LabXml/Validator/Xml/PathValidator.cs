using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Reflection;
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
                        using (var client = new TestWebClient())
                        {
                            client.HeadOnly = true;
                            var uriAccessible = false;

                            try
                            {
                                var tmp = client.DownloadString(path);
                                uriAccessible = true;
                            }
                            catch (WebException)
                            {
                                // Ignore 404
                            }

                            if (uriAccessible)
                            {
                                yield return new ValidationMessage()
                                {
                                    Message = "The URI could be accessed",
                                    TargetObject = path,
                                    Type = MessageType.Verbose
                                };
                            }
                            else
                            {
                                yield return new ValidationMessage()
                                {
                                    Message = "The URI could not be found",
                                    TargetObject = path,
                                    Type = MessageType.Error
                                };
                            }

                        }
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
    class TestWebClient : WebClient
    {
        public bool HeadOnly { get; set; }
        protected override WebRequest GetWebRequest(Uri address)
        {
            WebRequest req = base.GetWebRequest(address);
            if (HeadOnly && req.Method == "GET")
            {
                req.Method = "HEAD";
            }
            return req;
        }
    }
}
