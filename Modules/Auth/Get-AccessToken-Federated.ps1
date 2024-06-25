function Get-AccessToken-Federated {
    param(
        [Parameter(Mandatory)]
        [string]$ClientId,
        [Parameter(Mandatory)]
        [string]$ResourceUrl
    )

    try {

        Write-LogDebug "Connecting to Azure AD with ClientId $ClientId and TenantId $env:AZURE_TENANT_ID"
        Connect-AzAccount -ServicePrincipal -ApplicationId $ClientId `
                          -FederatedToken $(Get-Content $env:AZURE_FEDERATED_TOKEN_FILE -Raw) `
                          -Tenant $env:AZURE_TENANT_ID > $null

        Write-LogInfo "Generating Access Token for $ResourceUrl"
        return  (Get-AzAccessToken -ResourceUrl $ResourceUrl).Token

    }
    finally {
        Disconnect-AzAccount -ErrorAction SilentlyContinue | Out-Null
    }
}