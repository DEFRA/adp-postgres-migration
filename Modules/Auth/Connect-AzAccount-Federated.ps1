function Connect-AzAccount-Federated {
    param(
        [Parameter(Mandatory)]
        [string]$ClientId
        
    )

    Write-Debug "Connect to Azure using client Id $ClientId and Federated token"
    Connect-AzAccount -ServicePrincipal -ApplicationId $ClientId `
                      -FederatedToken $(Get-Content $env:AZURE_FEDERATED_TOKEN_FILE -Raw) `
                      -Tenant $env:AZURE_TENANT_ID  > $null
    Write-LogInfo "Connected to Azure account with Federated token"
            
}