@{
    ModuleVersion     = '1.0.0'
    GUID              = '2eedc4d3-385c-4f1d-b331-04d1382f8794'
    Author            = 'Defra ADP Team'
    CompanyName       = 'Defra'
    Copyright         = '(c) Defra. All rights reserved.'
    ScriptsToProcess = @(
        'Invoke-Migration.ps1'
    )
    FunctionsToExport = @(
        'Invoke-Migration'
    )
    
    CmdletsToExport   = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
        } 
    }    
}