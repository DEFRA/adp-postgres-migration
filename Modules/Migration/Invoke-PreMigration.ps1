function Invoke-PreMigration {
    param (
        [Parameter(Mandatory)]
        [string]$PostgresHost,

        [Parameter(Mandatory)]
        [string]$DbName,

        [Parameter(Mandatory)]
        [string]$ServiceMIName,

        [Parameter(Mandatory)]
        [string]$DbAdminMIName,

        [Parameter(Mandatory)]
        [string]$AdGroupDbReader,

        [Parameter(Mandatory)]
        [string]$AdGroupDbWriter
    )

    Write-LogInfo "Granting Postgres DB access to $ServiceMIName, $AdGroupDbReader and $AdGroupDbWriter for $DbName on $PostgresHost"

    Grant-PostgresDbAccess -PostgresHost $PostgresHost -DbName $DbName -DbAdminMIName $DbAdminMIName `
                           -ServiceMIName $ServiceMIName -AdGroupDbReader $AdGroupDbReader -AdGroupDbWriter $AdGroupDbWriter
                           
    Write-LogInfo "Postgres DB access granted to $ServiceMIName, $AdGroupDbReader and $AdGroupDbWriter for $DbName on $PostgresHost"
}
