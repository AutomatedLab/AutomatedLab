@{
    RootModule = 'AutomatedLabWorker.psm1'
    
    ModuleVersion = '4.1.1.0'
    
    GUID = '3addac35-cd7a-4bd2-82f5-ab9c83a48246'
    
    Author = 'Raimund Andree, Per Pedersen, Jan-Hendrik Peters'
    
    CompanyName = 'AutomatedLab Team'
    
    Copyright = '2016'
    
    Description = 'This module encapsulates all the work activities to prepare the lab'
    
    PowerShellVersion = '5.0'
    
    DotNetFrameworkVersion = '4.0'

	ModuleList = @('AutomatedLabWorker')

    RequiredModules = @(
        'AutomatedLabUnattended',
        'PSLog',
        'PSFileTransfer'
    )
    
    NestedModules = @(
        'AutomatedLabWorkerInternals.psm1',
        'AutomatedLabWorkerADCS.psm1',
        'AutomatedLabWorkerDisks.psm1',
        'AutomatedLabWorkerVirtualMachines.psm1',
        'AutomatedLabWorkerNetwork.psm1',
        'AutomatedLabAzureWorkerNetwork.psm1',
        'AutomatedLabAzureWorkerVirtualMachines.psm1',
        'AutomatedLabVMWareWorkerVirtualMachines.psm1',
    'AutomatedLabVMWareWorkerNetwork.psm1')
    
    FileList = @('AutomatedLabWorker.psm1',
        'AutomatedLabWorkerInternals.psm1', 
        'AutomatedLabWorkerADCS.psm1', 
        'AutomatedLabWorkerDisks.psm1',
        'AutomatedLabWorkerVirtualMachines.psm1',
        'AutomatedLabWorkerNetwork.psm1', 
        'AutomatedLabAzureWorkerNetwork.psm1',
        'AutomatedLabAzureWorkerVirtualMachines.psm1', 
        'AutomatedLabVMWareWorkerVirtualMachines.psm1',
    'AutomatedLabVMWareWorkerNetwork.psm1')

    PrivateData = @{
        SupportGen2VMs = $true
    }
}