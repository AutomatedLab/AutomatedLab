# CI/CD Pipeline

AutomatedLab now also lets you create release pipelines inside your lab by making use of AutomatedLab.Common's new TFS cmdlets.
## The lab
Your lab should include at least one TFS 2017 server and a suitable SQL 2016 server. You can use the sample provided at [DSC with release pipeline](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Scenarios/DSC%20With%20Release%20Pipeline.ps1).  
```powershell
Add-LabMachineDefinition -Roles Tfs2017
Add-LabMachineDefinition -Roles TfsBuildWorker # Optional, directly adds build workers to your TFS agent pools
```
## The pipeline
Before starting you should have an understanding of what a release pipeline is. There are plenty of resources out there. Especially for DSC, you could have a look [here](https://docs.microsoft.com/en-us/powershell/dsc/dsccicd).  
To add a new pipeline in AutomatedLab, there are only two cmdlets.
### Get-LabBuildStep
This cmdlet lists all available build steps that you can configure since there is not much documentation available. The output of Get-LabBuildStep can be copied and pasted with the correct formatting to use with New-LabReleasePipeline.
### New-LabReleasePipeline
This cmdlet goes through the necessary steps to create a new CI/CD pipeline. A project will be created, if specified a git repository will be forked and pushed to the new team project's repository and the build definition will be created.  
The build definition is the only thing that requires some though. Since a build definition consists of multiple build steps you will need to select for yourself which steps might make sense.
```powershell
$buildSteps = @(
    @{
        "enabled"         = $true
        "continueOnError" = $false
        "alwaysRun"       = $false
        "displayName"     = "Execute Build.ps1"
        "task"            = @{
            "id"          = "e213ff0f-5d5c-4791-802d-52ea3e7be1f1"
            "versionSpec" = "*"
        }
        "inputs"          = @{
            scriptType          = "filePath"
            scriptName          = ".Build.ps1"
            arguments           = "-resolveDependency"
            failOnStandardError = $false
        }
    }
)

# Clone the DSCInfraSample code and push the code to TFS while creating a new Project and the necessary build definitions
New-LabReleasePipeline -ProjectName 'ALSampleProject' -SourceRepository https://github.com/gaelcolas/DSCInfraSample -BuildSteps $buildSteps
```  
The ID you can see in the little code sample refers to the build step ID - this is part of the output of ``` Get-LabBuildStep ```:
```powershell
@{
            enabled         = True
            continueOnError = False
            alwaysRun       = False
            displayName     = 'YOUR OWN DISPLAY NAME HERE' # e.g. Archive files $(message) or Archive Files
            task            = @{
                id          = 'd8b84976-e99a-4b86-b885-4849694435b0'
                versionSpec = '*'
            }
            inputs          = @{
                                rootFolder = 'VALUE' # Type: filePath, Default: $(Build.BinariesDirectory), Mandatory: True
                                includeRootFolder = 'VALUE' # Type: boolean, Default: true, Mandatory: True
                                archiveType = 'VALUE' # Type: pickList, Default: default, Mandatory: True
                                tarCompression = 'VALUE' # Type: pickList, Default: gz, Mandatory: False
                                archiveFile = 'VALUE' # Type: filePath, Default: $(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip, Mandatory: True
                                replaceExistingArchive = 'VALUE' # Type: boolean, Default: true, Mandatory: True

            }
        }
```