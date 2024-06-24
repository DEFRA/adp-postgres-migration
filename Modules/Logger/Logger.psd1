@{
    ModuleVersion     = '1.0.0'
    GUID              = '7ebbe591-047a-4e0c-8ba1-930d7d8fd061'
    Author            = 'Defra ADP Team'
    CompanyName       = 'Defra'
    Copyright         = '(c) Defra. All rights reserved.'
    ScriptsToProcess = @(
        'Write-Log.ps1'
    )
    FunctionsToExport = @(
        'Write-LogInfo'
        'Write-LogError'
        'Write-LogDebug'
        'Write-LogWarning'
    )
    
    CmdletsToExport   = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
        } 
    }    
}