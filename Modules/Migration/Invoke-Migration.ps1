function Invoke-Migration {
    param(
        [Parameter(Mandatory)]
        [string]$PostgreHost,
        [Parameter(Mandatory)]
        [string]$PostgrePort,
        [Parameter(Mandatory)]
        [string]$DbName,
        [Parameter(Mandatory)]
        [string]$DbUserName,
        [Parameter(Mandatory)]
        [string]$ClientId,
        [Parameter(Mandatory)]
        [string]$ChangeLogFile,
        [Parameter(Mandatory)]
        [string]$DefaultSchemaName,
        [Parameter(Mandatory)]
        [string]$Command        
    )

    if (-not (Test-Path $ChangeLogFile)) {
        Write-LogError "Change log file $ChangeLogFile does not exist."
    }

    $liquibasePath = "/liquibase/liquibase"
    $defaultsFilePath = "/liquibase/liquibase.docker.properties"
    $driver = "org.postgresql.Driver"
    $url = "jdbc:postgresql://${PostgreHost}:${PostgrePort}/${DbName}"

    if (-not (Test-Path $defaultsFilePath)) {
        Write-LogError "Liquibase defaults file $defaultsFilePath does not exist."
    }

    $accessToken = Get-AccessToken-Federated -ClientId $ClientId -ResourceUrl "https://ossrdbms-aad.database.windows.net"
    
    Write-LogInfo "Migrating database: $DbName"
    $baseLiquibaseCommand = "$liquibasePath --defaultsFile=$defaultsFilePath --driver=$driver --url=$url --username='$($DbUserName)' --changeLogFile=$ChangeLogFile --defaultSchemaName='$($DefaultSchemaName)'"
    
    $maskedPassword = '********'
    Write-LogDebug "Executing Liquibase command: $baseLiquibaseCommand --password='$($maskedPassword)' $Command"
    $liquibaseCommand = "$baseLiquibaseCommand --password='$($accessToken)' $Command"
    Invoke-Expression $liquibaseCommand
    if ($LASTEXITCODE -ne 0) {
        Write-LogError "Database $DbName migration failed with error."
    }

    Write-LogInfo "Database $DbName migrated successfully."
}