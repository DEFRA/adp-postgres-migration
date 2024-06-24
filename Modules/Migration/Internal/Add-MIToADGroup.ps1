function Add-MIToADGroup(){
    param()

[string]$ManagedIdentityName = $env:TEAM_MI_NAME
[string]$ADGroupName = $env:PG_WRITER_AD_GROUP
[string]$ServicePrincipalClientId = $env:SP_CLIENT_ID_KV
[string]$ServicePrincipalClientSecret = $env:SP_CLIENT_SECRET_KV
[string]$KeyVaultName = $env:KEY_VAULT_NAME
[string]$TenantId = $env:AZURE_TENANT_ID
[string]$PlatformMIClientId = $env:AZURE_CLIENT_ID
[string]$PlatformMIFederatedTokenFile = $env:AZURE_FEDERATED_TOKEN_FILE
[string]$SubscriptionId = $env:SSV_SHARED_SUBSCRIPTION_ID
[string]$WorkingDirectory = $PWD

[string]$functionName = $MyInvocation.MyCommand
[DateTime]$startTime = [DateTime]::UtcNow
[int]$exitCode = -1
[bool]$setHostExitCode = (Test-Path -Path ENV:TF_BUILD) -and ($ENV:TF_BUILD -eq "true")
[bool]$enableDebug = (Test-Path -Path ENV:SYSTEM_DEBUG) -and ($ENV:SYSTEM_DEBUG -eq "true")

Set-Variable -Name ErrorActionPreference -Value Continue -Scope global
Set-Variable -Name VerbosePreference -Value Continue -Scope global

if ($enableDebug) {
    Set-Variable -Name DebugPreference -Value Continue -Scope global
    Set-Variable -Name InformationPreference -Value Continue -Scope global
}

Write-LogInfo "${functionName} started at $($startTime.ToString('u'))"
Write-LogDebug "${functionName}:ManagedIdentityName=$ManagedIdentityName"
Write-LogDebug "${functionName}:ADGroupName=$ADGroupName"
Write-LogDebug "${functionName}:ServicePrincipalClientId=$ServicePrincipalClientId"
Write-LogDebug "${functionName}:ServicePrincipalClientSecret=$ServicePrincipalClientSecret"
Write-LogDebug "${functionName}:KeyVaultName=$KeyVaultName"
Write-LogDebug "${functionName}:TenantId=$TenantId"
Write-LogDebug "${functionName}:PlatformMIClientId=$PlatformMIClientId"
Write-LogDebug "${functionName}:PlatformMIFederatedTokenFile=$PlatformMIFederatedTokenFile"
Write-LogDebug "${functionName}:SubscriptionId=$SubscriptionId"
Write-LogDebug "${functionName}:WorkingDirectory=$WorkingDirectory"

try {
    [System.IO.DirectoryInfo]$scriptDir = $PSCommandPath | Split-Path -Parent
    Write-LogDebug "${functionName}:scriptDir.FullName=$($scriptDir.FullName)"

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "common/scripts/modules/keyvault"
    Write-LogDebug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    Write-LogInfo "Connecting to Azure with Platform MI"
    $null = Connect-AzAccount -ServicePrincipal -ApplicationId $PlatformMIClientId -FederatedToken $(Get-Content $PlatformMIFederatedTokenFile -raw) -Tenant $TenantId -Subscription $SubscriptionId

    Write-LogInfo "Connected to Azure and set context to '$SubscriptionId'"

    $SPClientId = Get-KeyVaultSecret -KeyVaultName $KeyVaultName -SecretName $ServicePrincipalClientId
    $SPClientSecret = Get-KeyVaultSecret -KeyVaultName $KeyVaultName -SecretName $ServicePrincipalClientSecret

    Disconnect-AzAccount | Out-Null
    Write-LogInfo "Disconnected from Azure with Platform MI"

    $SecureClientSecret = ConvertTo-SecureString -String $SPClientSecret -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SPClientId, $SecureClientSecret

    Write-LogInfo "Connecting to Azure with Service Principal..."
    $null = Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential
    Write-LogInfo "Connected to Azure with Service Principal"

    if (-not (Get-Module -ListAvailable -Name 'Microsoft.Graph')) {
        Write-LogInfo "Microsoft.Graph doesn't exist. Installing module..."
        Install-Module Microsoft.Graph -Force -ErrorAction Stop
        Write-LogInfo "Microsoft.Graph module installed"
    }
    $accessToken = (Get-AzAccessToken -Resource https://graph.microsoft.com).Token
    $null = Connect-MgGraph -AccessToken ($accessToken | ConvertTo-SecureString -AsPlainText -Force)
    Write-LogInfo "Connected to Microsoft Graph"

    $adGroup = Get-MgGroup -Filter "DisplayName eq '$ADGroupName'"
    if ($adGroup) {
        Write-LogInfo "Identified AD group '$($adGroup.DisplayName)'"
        $managedId = Get-MgServicePrincipal -Filter "displayName eq '$ManagedIdentityName'" -ErrorAction Stop
        Write-LogInfo "Identified Managed Id '$($managedId.DisplayName)'"
        $null = New-MgGroupMember -GroupId $adGroup.Id -DirectoryObjectId $managedId.Id -ErrorAction Stop
        Write-LogInfo "Added Managed Identity '${ManagedIdentityName}' to AD group '${ADGroupName}'"
    }
    
    $exitCode = 0
}
catch {
    if ($_.Exception.Message.Contains("One or more added object references already exist")) {
        Write-LogInfo "Managed Identity already exists in AD group"
        $exitCode = 0
    }
    else {
        $exitCode = -2
        Write-LogError "Failed to add managed identity to AD group with exception: $($_.Exception.ToString())"
        throw $_.Exception
    }
}
finally {
    Disconnect-MgGraph | Out-Null
    [DateTime]$endTime = [DateTime]::UtcNow
    Write-LogInfo "${functionName} finished at $($endTime.ToString('u')) with exit code $exitCode"
    if ($setHostExitCode) {
        Write-LogDebug "${functionName}:Setting host exit code"
        $host.SetShouldExit($exitCode)
    }
    exit $exitCode
}

}