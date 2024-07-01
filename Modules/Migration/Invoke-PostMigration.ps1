function Invoke-PostMigration {
    param(
        [Parameter(Mandatory)]
        [string]$PostgresHost,

        [Parameter(Mandatory)]
        [string]$DbName,

        [Parameter(Mandatory)]
        [string]$DbUserName,

        [Parameter(Mandatory)]
        [string]$ServiceMIName,

        [Parameter(Mandatory)]
        [string]$AdGroupDbReader,

        [Parameter(Mandatory)]
        [string]$ClientId
    )
    
    Write-LogInfo "Granting Database scheams access to $ServiceMIName for $DbName on $PostgresHost"

    $accessToken = Get-AccessToken-Federated -ClientId $ClientId -ResourceUrl "https://ossrdbms-aad.database.windows.net"
    
    Grant-PostgresDBScheamAccess -PostgresHost $PostgresHost -DbName $DbName `
                                 -DbUserName $DbUserName -ServiceMIName $ServiceMIName `
                                 -AccessToken $accessToken `
                                 -AdGroupDbReader $AdGroupDbReader
}