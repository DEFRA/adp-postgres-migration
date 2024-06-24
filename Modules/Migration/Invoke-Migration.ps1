function Invoke-Migration {
    param(
        [Parameter(Mandatory)]
        [string]$PostgreHost,
        [Parameter(Mandatory)]
        [string]$PostgrePort,
        [Parameter(Mandatory)]
        [string]$DatabaseName,
        [Parameter(Mandatory)]
        [string]$UserName,
        [Parameter(Mandatory)]
        [string]$AccessToken ,
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
    $url = "jdbc:postgresql://${PostgreHost}:${PostgrePort}/${DatabaseName}"

    if (-not (Test-Path $defaultsFilePath)) {
        Write-LogError "Liquibase defaults file $defaultsFilePath does not exist."
    }

    Write-LogInfo "Migrating database: $DatabaseName"
    $baseLiquibaseCommand = "$liquibasePath --defaultsFile=$defaultsFilePath --driver=$driver --url=$url --username='$($UserName)' --changeLogFile=$ChangeLogFile --defaultSchemaName='$($DefaultSchemaName)'"
    
    Write-LogInfo "Executing Liquibase status..."
    $maskedPassword = '********'  
    Write-LogDebug "Executing Liquibase command: $baseLiquibaseCommand --password='$($maskedPassword)' status"
    $liquibaseCommand = "$baseLiquibaseCommand --password='$($AccessToken)' status"
    Invoke-Expression $liquibaseCommand
    if ($LASTEXITCODE -ne 0) {
        Write-LogError "Liquibase status failed with error."
    }
    
    Write-LogDebug "Executing Liquibase command: $baseLiquibaseCommand --password='$($maskedPassword)' $Command"
    $liquibaseCommand = "$baseLiquibaseCommand --password='$($AccessToken)' $Command"
    Invoke-Expression $liquibaseCommand
    if ($LASTEXITCODE -ne 0) {
        Write-LogError "Database $DatabaseName migration failed with error."
    }

    Write-LogInfo "Database $DatabaseName migrated successfully."
}