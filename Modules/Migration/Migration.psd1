@{
    ModuleVersion     = '1.0.0'
    GUID              = '2eedc4d3-385c-4f1d-b331-04d1382f8794'
    Author            = 'Defra ADP Team'
    CompanyName       = 'Defra'
    Copyright         = '(c) Defra. All rights reserved.'
    ScriptsToProcess = @(
        'Internal/Invoke-PSQLScript.ps1'
        'Internal/Grant-PostgresDbAccess.ps1'
        'Internal/Grant-PostgresDBScheamAccess.ps1'
        'Internal/Add-MIToADGroup.ps1'
        'Invoke-PreMigration.ps1'
        'Invoke-Migration.ps1'
        'Invoke-PostMigration.ps1'
    )
    FunctionsToExport = @(
        'Invoke-PreMigration'
        'Invoke-Migration'
        'Invoke-PostMigration'
    )

    RequiredModules   = @(
        '/Modules/Logger/Logger.psd1'
        '/Modules/Auth/Auth.psd1'
    )
    
    CmdletsToExport   = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
        } 
    }    
    
}