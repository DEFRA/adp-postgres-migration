param(
    [ValidateSet("update")]
    [string]$Command,

    [Parameter(Mandatory)]
    [string]$ChangeLogFile
)
function Test-EnvironmentVariables {
    $requiredVariables = @(
        "POSTGRES_HOST", "POSTGRES_PORT", "POSTGRES_DB_NAME", "POSTGRES_DB_USERNAME","SCHEMA_NAME", 
        "PLATFORM_MI_NAME","TEAM_MI_NAME","SERVICE_MI_NAME",
        "PG_WRITER_AD_GROUP","PG_READER_AD_GROUP", 
        "SSV_SHARED_SUBSCRIPTION_ID","DB_AAD_ADMIN_CLIENT_ID", "AZURE_TENANT_ID","TEAM_MI_CLIENT_ID", 
        "KEY_VAULT_NAME", "SP_CLIENT_ID_KV", "SP_CLIENT_SECRET_KV"
    )
    $missingVariables = $requiredVariables | Where-Object { 
        [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_)) 
    }
    if ($null -ne $missingVariables -and $missingVariables.Count -gt 0) {
        Write-LogError "Missing required variables: $($missingVariables -join ', ')"
    }

    if (-not $env:AZURE_FEDERATED_TOKEN_FILE -or -not (Test-Path $env:AZURE_FEDERATED_TOKEN_FILE)) {
        Write-LogError "Federated token file not found"
    }
}

Set-StrictMode -Version 3.0

Import-Module -Name Logger
Import-Module -Name Migration

try {
    
    Write-LogInfo "Validating environment variables..."
    Test-EnvironmentVariables

    Write-LogInfo "Starting pre-migration..."
    Invoke-PreMigration -Postgres @{ Host = $env:POSTGRES_HOST ; DbName = $env:POSTGRES_DB_NAME } `
                        -DbAdmin @{ MIName =  $env:PLATFORM_MI_NAME ; ClientId = $env:DB_AAD_ADMIN_CLIENT_ID } `
                        -AdGroups: @{ DbReader =  $env:PG_READER_AD_GROUP ; DbWriter =  $env:PG_WRITER_AD_GROUP } `
                        -KeyVaultName $env:KEY_VAULT_NAME `
                        -SPNSecretNames @{ clientIdName = $env:SP_CLIENT_ID_KV; clientSecretName = $env:SP_CLIENT_SECRET_KV } `
                        -ServiceMIName $env:SERVICE_MI_NAME -TeamMIName $env:TEAM_MI_NAME `
                        -SubscriptionId $env:SSV_SHARED_SUBSCRIPTION_ID -TenantId $env:AZURE_TENANT_ID 

    Write-LogInfo "Starting migration..."
    Invoke-Migration -PostgreHost $env:POSTGRES_HOST -PostgrePort $env:POSTGRES_PORT `
                     -DbName $env:POSTGRES_DB_NAME -DbUserName $env:POSTGRES_DB_USERNAME `
                     -ClientId $env:TEAM_MI_CLIENT_ID -ChangeLogFile $ChangeLogFile `
                     -DefaultSchemaName $env:SCHEMA_NAME -Command $Command.ToLower()
    
    Write-LogInfo "Starting post-migration..."        
    Invoke-PostMigration -PostgresHost $env:POSTGRES_HOST `
                         -DbName $env:POSTGRES_DB_NAME -DbUserName $env:POSTGRES_DB_USERNAME `
                         -ServiceMIName $env:SERVICE_MI_NAME -AdGroupDbReader $env:PG_READER_AD_GROUP `
                         -ClientId $env:TEAM_MI_CLIENT_ID
}
catch {
    Write-LogError -Message "Migration failed: $_"
}