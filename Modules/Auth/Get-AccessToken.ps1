function Get-AccessToken {
    param(
        [Parameter(Mandatory)]
        [string]$ClientId,

        [Parameter(Mandatory)]
        [string]$ClientSecret,

        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [string]$ResourceUrl
    )

    try {

        $secureClientSecret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $secureClientSecret

        Write-LogDebug "Connecting to Azure AD with ClientId $ClientId and TenantId $TenantId"
        Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential | Out-Null

        Write-LogInfo "Generating Access Token for $ResourceUrl"
        return  (Get-AzAccessToken -ResourceUrl $ResourceUrl).Token

    }
    finally {
        Disconnect-AzAccount -ErrorAction SilentlyContinue | Out-Null
    }
}