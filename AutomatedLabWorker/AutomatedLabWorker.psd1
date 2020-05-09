@{
    RootModule             = 'AutomatedLabWorker.psm1'

    ModuleVersion          = '1.0.0'

    CompatiblePSEditions   = 'Core', 'Desktop'

    GUID                   = '3addac35-cd7a-4bd2-82f5-ab9c83a48246'

    Author                 = 'Raimund Andree, Per Pedersen, Jan-Hendrik Peters'

    CompanyName            = 'AutomatedLab Team'

    Copyright              = '2019'

    Description            = 'This module encapsulates all the work activities to prepare the lab'

    PowerShellVersion      = '5.1'

    DotNetFrameworkVersion = '4.0'

    ModuleList             = @('AutomatedLabWorker')

    RequiredModules        = @(
        'AutomatedLabUnattended',
        'PSLog',
        'PSFileTransfer',
        @{
            ModuleName    = "AutomatedLab.Common";
            ModuleVersion = "1.1.87";
        }
    )

    NestedModules          = @(
        'AutomatedLabWorkerInternals.psm1',
        'AutomatedLabWorkerADCS.psm1',
        'AutomatedLabWorkerDisks.psm1',
        'AutomatedLabWorkerVirtualMachines.psm1',
        'AutomatedLabWorkerNetwork.psm1',
        'AutomatedLabAzureWorkerNetwork.psm1',
        'AutomatedLabAzureWorkerVirtualMachines.psm1',
        'AutomatedLabVMWareWorkerVirtualMachines.psm1',
        'AutomatedLabVMWareWorkerNetwork.psm1')

    FileList               = @('AutomatedLabWorker.psm1',
        'AutomatedLabWorkerInternals.psm1',
        'AutomatedLabWorkerADCS.psm1',
        'AutomatedLabWorkerDisks.psm1',
        'AutomatedLabWorkerVirtualMachines.psm1',
        'AutomatedLabWorkerNetwork.psm1',
        'AutomatedLabAzureWorkerNetwork.psm1',
        'AutomatedLabAzureWorkerVirtualMachines.psm1',
        'AutomatedLabVMWareWorkerVirtualMachines.psm1',
        'AutomatedLabVMWareWorkerNetwork.psm1')

    PrivateData            = @{ }
}
