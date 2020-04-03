# Telemetry

AutomatedLab has started to collect telemetry starting with version 5.0. This is an opt-in collection and you will be asked once to specify whether or not you want to send us telemetry data. It is important for us to stress that we of course do not collect any personally identifiable data. We simply want to know what you do with AutomatedLab to be able to decide what we want to develop.

If at any time you want to disable telemetry, simply use `Disable-LabTelemtry`.

## What metrics are collected?
We are collecting the following metrics with Azure Application Insights:
- Lab started - Timestamp
  - Amount of Machines
  - Used roles
  - Your AutomatedLab version
  - Your OS version
  - Your PowerShell version
  - The lab hypervisor type, i.e. Hyper-V, VMWare or Azure
- Lab finished - Timestamp
  - DayOfWeek
  - Time taken in seconds
- Coarse Geolocation (Country you are coming from) - Your IP address is NOT recorded.  
You can find all code that is used to provide telemetry here to inspect it yourself: https://github.com/AutomatedLab/AutomatedLab/blob/master/LabXml/Telemetry/LabTelemetry.cs  
If you are not connected to the internet, telemetry will silently fail. If no data can be sent, it will silently fail as well. There is no noticeable impact, and telemetry is sent only twice. Once at the beginning and once at the end of Install-Lab.  

## Why collect data at all?

We are collecting this data to get an insight where and how AutomatedLab is used. We would like to see which roles are popular, how big the average lab is and how long it takes to deploy. We hope to gain valuable insights into how popular (or unpopular) the module is and which roles are used.

We are also keen on knowing how many different (and possibly old) versions there are in the field. This for example can show us that we need to announce new releases better.

## I want to opt out!

Sure thing. We've got you covered: By default you are not even opted in. Should you want to opt out or in at a later stage,either of the following works:
- Create an environmental variable called `AUTOMATEDLAB_TELEMETRY_OPTIN` which contains 0, false, or no to opt out or 1, true or yes to opt in
- Use the cmdlet `Disable-LabTelemetry` to opt out or `Enable-LabTelemetry` to opt in

## What data to I give away? How do I know you don't transmit my darkest secrets?

The following JSON data is live data that we used during testing - this is what will actually be collected:
```JSON
{
    "event": [{
        "name": "Role",
        "count": 1
    }],
    "internal": {
        "data": {
            "id": "db41d380-31eb-11e8-bdf2-ebbdaa4a8265",
            "documentVersion": "1.61"
        }
    },
    "context": {
        "data": {
            "eventTime": "2018-03-27T18:22:50.117Z",
            "isSynthetic": false,
            "samplingRate": 100.0
        },
        "cloud": {},
        "device": {
            "type": "PC",
            "roleName": "nope",
            "roleInstance": "nope",
            "screenResolution": {}
        },
        "user": {
            "isAuthenticated": false
        },
        "session": {
            "isFirst": false
        },
        "operation": {},
        "location": {
            "clientip": "0.0.0.0",
            "continent": "Europe",
            "country": "Germany"
        },
        "custom": {
            "dimensions": [{
                "ai.device.RoleInstance": "nope"
            }, {
                "role": "RootDC"
            }]
        }
    }
} {
    "event": [{
        "name": "Role",
        "count": 1
    }],
    "internal": {
        "data": {
            "id": "db6cb412-31eb-11e8-bdf2-ebbdaa4a8265",
            "documentVersion": "1.61"
        }
    },
    "context": {
        "data": {
            "eventTime": "2018-03-27T18:22:51.163Z",
            "isSynthetic": false,
            "samplingRate": 100.0
        },
        "cloud": {},
        "device": {
            "type": "PC",
            "roleName": "nope",
            "roleInstance": "nope",
            "screenResolution": {}
        },
        "user": {
            "isAuthenticated": false
        },
        "session": {
            "isFirst": false
        },
        "operation": {},
        "location": {
            "clientip": "0.0.0.0",
            "continent": "Europe",
            "country": "Germany"
        },
        "custom": {
            "dimensions": [{
                "ai.device.RoleInstance": "nope"
            }, {
                "role": "CaRoot"
            }]
        }
    }
} {
    "event": [{
        "name": "Role",
        "count": 1
    }],
    "internal": {
        "data": {
            "id": "db6cb413-31eb-11e8-bdf2-ebbdaa4a8265",
            "documentVersion": "1.61"
        }
    },
    "context": {
        "data": {
            "eventTime": "2018-03-27T18:22:51.164Z",
            "isSynthetic": false,
            "samplingRate": 100.0
        },
        "cloud": {},
        "device": {
            "type": "PC",
            "roleName": "nope",
            "roleInstance": "nope",
            "screenResolution": {}
        },
        "user": {
            "isAuthenticated": false
        },
        "session": {
            "isFirst": false
        },
        "operation": {},
        "location": {
            "clientip": "0.0.0.0",
            "continent": "Europe",
            "country": "Germany"
        },
        "custom": {
            "dimensions": [{
                "ai.device.RoleInstance": "nope"
            }, {
                "role": "SQLServer2016"
            }]
        }
    }
} {
    "event": [{
        "name": "Role",
        "count": 1
    }],
    "internal": {
        "data": {
            "id": "dbeb59f7-31eb-11e8-b662-1fbb2945797c",
            "documentVersion": "1.61"
        }
    },
    "context": {
        "data": {
            "eventTime": "2018-03-27T18:22:51.663Z",
            "isSynthetic": false,
            "samplingRate": 100.0
        },
        "cloud": {},
        "device": {
            "type": "PC",
            "roleName": "nope",
            "roleInstance": "nope",
            "screenResolution": {}
        },
        "user": {
            "isAuthenticated": false
        },
        "session": {
            "isFirst": false
        },
        "operation": {},
        "location": {
            "clientip": "0.0.0.0",
            "continent": "Europe",
            "country": "Germany"
        },
        "custom": {
            "dimensions": [{
                "ai.device.RoleInstance": "nope"
            }, {
                "role": "DSCPullServer"
            }]
        }
    }
} {
    "event": [{
        "name": "Role",
        "count": 1
    }],
    "internal": {
        "data": {
            "id": "dbeb59f8-31eb-11e8-b662-1fbb2945797c",
            "documentVersion": "1.61"
        }
    },
    "context": {
        "data": {
            "eventTime": "2018-03-27T18:22:51.666Z",
            "isSynthetic": false,
            "samplingRate": 100.0
        },
        "cloud": {},
        "device": {
            "type": "PC",
            "roleName": "nope",
            "roleInstance": "nope",
            "screenResolution": {}
        },
        "user": {
            "isAuthenticated": false
        },
        "session": {
            "isFirst": false
        },
        "operation": {},
        "location": {
            "clientip": "0.0.0.0",
            "continent": "Europe",
            "country": "Germany"
        },
        "custom": {
            "dimensions": [{
                "ai.device.RoleInstance": "nope"
            }, {
                "role": "TfsBuildWorker"
            }]
        }
    }
} {
    "event": [{
        "name": "Role",
        "count": 1
    }],
    "internal": {
        "data": {
            "id": "dc4a90f0-31eb-11e8-9356-5595949951eb",
            "documentVersion": "1.61"
        }
    },
    "context": {
        "data": {
            "eventTime": "2018-03-27T18:22:52.255Z",
            "isSynthetic": false,
            "samplingRate": 100.0
        },
        "cloud": {},
        "device": {
            "type": "PC",
            "roleName": "nope",
            "roleInstance": "nope",
            "screenResolution": {}
        },
        "user": {
            "isAuthenticated": false
        },
        "session": {
            "isFirst": false
        },
        "operation": {},
        "location": {
            "clientip": "0.0.0.0",
            "continent": "Europe",
            "country": "Germany"
        },
        "custom": {
            "dimensions": [{
                "ai.device.RoleInstance": "nope"
            }, {
                "role": "Tfs2017"
            }]
        }
    }
} {
    "event": [{
        "name": "LabStarted",
        "count": 1
    }],
    "internal": {
        "data": {
            "id": "dcaed100-31eb-11e8-b662-1fbb2945797c",
            "documentVersion": "1.61"
        }
    },
    "context": {
        "data": {
            "eventTime": "2018-03-27T18:22:53.251Z",
            "isSynthetic": false,
            "samplingRate": 100.0
        },
        "cloud": {},
        "device": {
            "type": "PC",
            "roleName": "nope",
            "roleInstance": "nope",
            "screenResolution": {}
        },
        "user": {
            "isAuthenticated": false
        },
        "session": {
            "isFirst": false
        },
        "operation": {},
        "location": {
            "clientip": "0.0.0.0",
            "continent": "Europe",
            "country": "Germany"
        },
        "custom": {
            "dimensions": [{
                "version": "1.2.3.4"
            }, {
                "ai.device.RoleInstance": "nope"
            }, {
                "osversion": "1.2.3.4"
            }, {
                "hypervisor": "Azure"
            }],
            "metrics": [{
                "machineCount": {
                    "count": 1.0,
                    "max": 4.0,
                    "min": 4.0,
                    "sampledValue": 4.0,
                    "stdDev": 0.0,
                    "sum": 4.0,
                    "value": 4.0
                }
            }]
        }
    }
}
```  


In case you are wondering about RoleInstance (which would by default be your computer name): We intentionally set this to "nope" to strip away any identifiable information - we don't care about this stuff at all!
