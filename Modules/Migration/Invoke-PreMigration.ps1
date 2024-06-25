function Invoke-PreMigration {
    param (
        [Parameter(Mandatory)]
        [object]$Postgres,

        [Parameter(Mandatory)]
        [object]$DbAdmin,

        [Parameter(Mandatory)]
        [object]$AdGroups,

        [Parameter(Mandatory)]
        [object]$SPNSecretNames,

        [Parameter(Mandatory)]
        [string]$KeyVaultName,

        [Parameter(Mandatory)]
        [string]$ServiceMIName,

        [Parameter(Mandatory)]
        [string]$TenantId
    )

    try {
        
        Connect-AzAccount-Federated -ClientId $DbAdmin.ClientId

        Write-LogInfo "Granting Postgres DB access to $ServiceMIName, $($AdGroups.DbReader) and $($AdGroups.DbWriter) for $($Postgres.DbName) on $($Postgres.Host)"
        $pgpassword = (Get-AzAccessToken -ResourceUrl "https://ossrdbms-aad.database.windows.net").Token
        Grant-PostgresDbAccess -PostgresHost $Postgres.Host -DbName $Postgres.DbName `
            -DbAdminMIName $DbAdmin.MIName -ServiceMIName $ServiceMIName `
            -AccessToken $pgpassword -AdGroupDbReader $AdGroups.DbReader -AdGroupDbWriter $AdGroups.DbWriter                           
        Write-LogInfo "Granted Postgres DB access to $ServiceMIName, $($AdGroups.DbReader) and $($AdGroups.DbWriter) for $($Postgres.DbName) on $($Postgres.Host)"
        
        Write-LogInfo "Adding member $ServiceMIName to $($AdGroups.DbWriter)"
        $spnClientId = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SPNSecretNames.clientIdName -AsPlainText -Debug:$false
        $spnClientSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SPNSecretNames.clientSecretName -AsPlainText -Debug:$false
        Add-MIToADGroup -MIName $ServiceMIName -ADGroupName $AdGroups.DbWriter -ClientId $spnClientId -ClientSecret $spnClientSecret -TenantId $TenantId
    }
    finally {
        Disconnect-AzAccount -ErrorAction SilentlyContinue | Out-Null
    }
}
