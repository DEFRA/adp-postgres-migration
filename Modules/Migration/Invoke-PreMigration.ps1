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
        [string]$TeamMIName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [Parameter(Mandatory)]
        [string]$TenantId
    )

    try {
       
        $null = Connect-AzAccount-Federated -ClientId $DbAdmin.ClientId 
        $null = Set-AzContext -Subscription $SubscriptionId -ErrorAction Stop

        $spnClientId = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SPNSecretNames.clientIdName -AsPlainText).Trim()
        $spnClientSecret = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SPNSecretNames.clientSecretName -AsPlainText).Trim()

        # Grant PostgreSQL Database access
        Write-LogInfo "Granting Database access to $ServiceMIName, $($AdGroups.DbReader) and $($AdGroups.DbWriter) for $($Postgres.DbName) on $($Postgres.Host)" 
        $pgpassword = (Get-AzAccessToken -ResourceUrl "https://ossrdbms-aad.database.windows.net").Token
        
        Grant-PostgresDbAccess -PostgresHost $Postgres.Host -DbName $Postgres.DbName `
            -DbAdminMIName $DbAdmin.MIName -ServiceMIName $ServiceMIName `
            -AccessToken $pgpassword -AdGroupDbReader $AdGroups.DbReader -AdGroupDbWriter $AdGroups.DbWriter
        
        # Add member to AD Group
        Write-LogInfo "Adding member $TeamMIName to $($AdGroups.DbWriter)"
        Add-MIToADGroup -MIName $TeamMIName -ADGroupName $AdGroups.DbWriter -ClientId $spnClientId -ClientSecret $spnClientSecret -TenantId $TenantId

    }
    finally {
        $null = Disconnect-AzAccount -ErrorAction SilentlyContinue
    }
}
