# OSUpdates folder

You can store all OS Updates you want to apply to your lab environment. These updates will not be applied to all lab VMs automatically
as this takes quite a long time. Rather the updates in this folder can be used to create a new ISO from which you can install all your
new VMs.

The is a demo script that explains how to create a new ISO file: [11 ISO Offline Patching.ps1](https://github.com/AutomatedLab/AutomatedLab/blob/develop/LabSources/SampleScripts/Introduction/11%20ISO%20Offline%20Patching.ps1).

The cmdlet for creating new ISOs is Update-LabIsoImage.