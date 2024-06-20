@{
    ModuleVersion     = '1.0.0'
    GUID              = '58490b96-aa19-4b84-9e93-94b2df16c83f'
    Author            = 'Defra ADP Team'
    CompanyName       = 'Defra'
    Copyright         = '(c) Defra. All rights reserved.'
    ScriptsToProcess = @('Invoke-PostMigration.ps1')
    FunctionsToExport = @(
        'Invoke-PostMigration'
    )
    
    CmdletsToExport   = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
        } 
    }    
}