@{
    ModuleVersion     = '1.0.0'
    GUID              = '513e148d-0de9-4589-a624-a60d7f8070ba'
    Author            = 'Defra ADP Team'
    CompanyName       = 'Defra'
    Copyright         = '(c) Defra. All rights reserved.'
    ScriptsToProcess = @(
        'Connect-AzAccount-Federated.ps1',
        'Get-AccessToken.ps1',
        'Get-AccessToken-Federated.ps1'        
    )
    FunctionsToExport = @(
       'Connect-AzAccount-Federated',
       'Get-AccessToken',
        'Get-AccessToken-Federated'
    )

    RequiredModules   = @(
        '/Modules/Logger/Logger.psd1'
    )
    
    CmdletsToExport   = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
        } 
    }    
}