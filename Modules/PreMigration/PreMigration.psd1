@{
    ModuleVersion     = '1.0.0'
    GUID              = '23e1d032-9704-47f1-a2f3-c39e4a0c3599'
    Author            = 'Defra ADP Team'
    CompanyName       = 'Defra'
    Copyright         = '(c) Defra. All rights reserved.'
    ScriptsToProcess = @('Invoke-PreMigration.ps1')
  
    FunctionsToExport = @(
        'Invoke-PreMigration'
    )

    RequiredModules   = @(
        '/Logger/Logger.psd1'
    )
    
    CmdletsToExport   = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
        } 
    }    
}