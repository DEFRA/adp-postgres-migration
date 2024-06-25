param(
    [ValidateSet("update", "rollback")]
    [string]$Command,

    [Parameter(Mandatory)]
    [string]$ChangeLogFile
)
function Test-EnvironmentVariables {
    $requiredVariables = @(
        "POSTGRE_HOST", 
        "POSTGRE_PORT", 
        "POSTGRE_DB_NAME", 
        "SCHEMA_USERNAME",
        "POSTGRE_SCHEMA",
        "SERVICE_MI_NAME",
        "PLATFORM_MI_NAME",
        "PG_WRITER_AD_GROUP",
        "PG_READER_AD_GROUP",
        "DB_AAD_ADMIN_CLIENT_ID",
        "AZURE_TENANT_ID",
        "TEAM_MI_CLIENT_ID",
        "KEY_VAULT_NAME",
        "SP_CLIENT_ID_KV",
        "SP_CLIENT_SECRET_KV"
    )
    $missingVariables = $requiredVariables | Where-Object { 
        [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_)) 
    }
    if ($missingVariables.Count -gt 0) {
        Write-LogError "The following environment variables are either not set or have no value: $($missingVariables -join ', ')"
    }

    if (-not $env:AZURE_FEDERATED_TOKEN_FILE -or -not (Test-Path  $env:AZURE_FEDERATED_TOKEN_FILE)) {
        Write-LogError "Federated token file not found"
    }
}

Import-Module -Name Logger
Import-Module -Name Migration

try {
    Test-EnvironmentVariables
    Invoke-PreMigration `
        -Postgres @{ Host = $env:POSTGRE_HOST ; DbName = $env:POSTGRE_DB_NAME } `
        -DbAdmin @{ MIName =  $env:PLATFORM_MI_NAME ; ClientId = $env:DB_AAD_ADMIN_CLIENT_ID } `
        -AdGroups: @{ DbReader =  $env:PG_READER_AD_GROUP ; DbWriter =  $env:PG_WRITER_AD_GROUP } `
        -KeyVaultName $env:KEY_VAULT_NAME `
        -SPNSecretNames @{ clientIdName = $env:SP_CLIENT_ID_KV; clientSecretName = $env:SP_CLIENT_SECRET_KV } `
        -ServiceMIName $env:SERVICE_MI_NAME `
        -TenantId $env:AZURE_TENANT_ID 

    Write-LogInfo "Starting migration process..."
    Invoke-Migration `
        -PostgreHost $env:POSTGRE_HOST `
        -PostgrePort $env:POSTGRE_PORT `
        -DbName $env:POSTGRE_DB_NAME `
        -UserName $env:SCHEMA_USERNAME `
        -ClientId $env:TEAM_MI_CLIENT_ID `
        -ChangeLogFile $ChangeLogFile `
        -DefaultSchemaName $env:POSTGRE_SCHEMA `
        -Command $Command.ToLower()
    
    Invoke-PostMigration
}
catch {
    Write-LogError -Message "Migration process failed: $_"
}