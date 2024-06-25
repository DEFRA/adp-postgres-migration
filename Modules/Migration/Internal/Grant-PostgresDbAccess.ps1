function Grant-PostgresDbAccess {
    param (
        [Parameter(Mandatory)]    
        [string]$PostgresHost,

        [Parameter(Mandatory)]
        [string]$DbName,

        [Parameter(Mandatory)]
        [string]$DbAdminMIName,

        [Parameter(Mandatory)]
        [string]$ServiceMIName,

        [Parameter(Mandatory)]
        [string]$AccessToken,

        [Parameter(Mandatory)]
        [string]$AdGroupDbReader,

        [Parameter(Mandatory)]
        [string]$AdGroupDbWriter
    )
    
    function Get-SQLScriptToCreatePrincipal {
        [System.Text.StringBuilder]$builder = [System.Text.StringBuilder]::new()
        [void]$builder.Append(' DO $$ ')
        [void]$builder.Append(' BEGIN ')
        [void]$builder.Append("     IF NOT EXISTS (SELECT 1 FROM pgaadauth_list_principals(false) WHERE rolname='$AdGroupDbWriter') THEN ")
        [void]$builder.Append("         RAISE NOTICE 'CREATING PRINCIPAL FOR MANAGED IDENTITY:$AdGroupDbWriter';")
        [void]$builder.Append("         PERFORM pgaadauth_create_principal('$AdGroupDbWriter', false, false); ");
        [void]$builder.Append("         RAISE NOTICE 'PRINCIPAL FOR MANAGED IDENTITY CREATED:$AdGroupDbWriter';")
        [void]$builder.Append('     ELSE ')
        [void]$builder.Append("         RAISE NOTICE 'PRINCIPAL FOR MANAGED IDENTITY ALREADY EXISTS:$AdGroupDbWriter';")
        [void]$builder.Append('     END IF; ')
        [void]$builder.Append("     IF NOT EXISTS (SELECT 1 FROM pgaadauth_list_principals(false) WHERE rolname='$AdGroupDbReader') THEN ")
        [void]$builder.Append("         RAISE NOTICE 'CREATING PRINCIPAL FOR MANAGED IDENTITY:$AdGroupDbReader';")
        [void]$builder.Append("         PERFORM pgaadauth_create_principal('$AdGroupDbReader', false, false); ");
        [void]$builder.Append("         RAISE NOTICE 'PRINCIPAL FOR MANAGED IDENTITY CREATED:$AdGroupDbReader';")
        [void]$builder.Append('     ELSE ')
        [void]$builder.Append("         RAISE NOTICE 'PRINCIPAL FOR MANAGED IDENTITY ALREADY EXISTS:$AdGroupDbReader';")
        [void]$builder.Append('     END IF; ')
        [void]$builder.Append("     IF NOT EXISTS (SELECT 1 FROM pgaadauth_list_principals(false) WHERE rolname='$ServiceMIName') THEN ")
        [void]$builder.Append("         RAISE NOTICE 'CREATING PRINCIPAL FOR MANAGED IDENTITY:$ServiceMIName';")
        [void]$builder.Append("         PERFORM pgaadauth_create_principal('$ServiceMIName', false, false); ");
        [void]$builder.Append("         RAISE NOTICE 'PRINCIPAL FOR MANAGED IDENTITY CREATED:$ServiceMIName';")
        [void]$builder.Append('     ELSE ')
        [void]$builder.Append("         RAISE NOTICE 'PRINCIPAL FOR MANAGED IDENTITY ALREADY EXISTS:$ServiceMIName';")
        [void]$builder.Append('     END IF; ')
        [void]$builder.Append("     EXECUTE ( 'GRANT CONNECT ON DATABASE `"$DbName`" TO `"$AdGroupDbWriter`"' );")
        [void]$builder.Append("     EXECUTE ( 'GRANT CONNECT ON DATABASE `"$DbName`" TO `"$AdGroupDbReader`"' );")
        [void]$builder.Append("     EXECUTE ( 'GRANT CONNECT ON DATABASE `"$DbName`" TO `"$ServiceMIName`"' );")
        [void]$builder.Append("     RAISE NOTICE 'GRANTED CONNECT TO DATABASE';")
        [void]$builder.Append(" EXCEPTION ")
        [void]$builder.Append("     WHEN OTHERS THEN  ")
        [void]$builder.Append("         RAISE EXCEPTION 'ERROR DURING PRINCIPAL CREATION/GRANT CONNECT: %', SQLERRM; ")
        [void]$builder.Append(' END $$' )
        return $builder.ToString()
    }

    function Get-SQLScriptToGrantAllPermissions {
        [System.Text.StringBuilder]$builder = [System.Text.StringBuilder]::new()
        [void]$builder.Append("GRANT ALL ON SCHEMA public TO `"$AdGroupDbWriter`";")
        [void]$builder.Append("GRANT ALL ON ALL TABLES IN SCHEMA public TO `"$AdGroupDbWriter`";")
        [void]$builder.Append("GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO `"$AdGroupDbWriter`";")
        [void]$builder.Append("GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO `"$AdGroupDbWriter`";")
        [void]$builder.Append("GRANT ALL ON ALL PROCEDURES IN SCHEMA public TO `"$AdGroupDbWriter`";")
        return $builder.ToString()
    }

    function Get-SQLScriptToGrantReadPermissions {
        [System.Text.StringBuilder]$builder = [System.Text.StringBuilder]::new()
        [void]$builder.Append("GRANT USAGE ON SCHEMA public TO `"$AdGroupDbReader`";")
        [void]$builder.Append("GRANT SELECT ON ALL TABLES IN SCHEMA public TO `"$AdGroupDbReader`";")
        [void]$builder.Append("GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO `"$AdGroupDbReader`";")
        [void]$builder.Append("REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM `"$AdGroupDbReader`";")
        [void]$builder.Append("REVOKE EXECUTE ON ALL PROCEDURES IN SCHEMA public FROM `"$AdGroupDbReader`";")
        return $builder.ToString()
    }

    function Get-SQLScriptToGrantApplicationPermissions {
        [System.Text.StringBuilder]$builder = [System.Text.StringBuilder]::new()
        [void]$builder.Append("GRANT CREATE, USAGE ON SCHEMA public TO `"$ServiceMIName`";")
        [void]$builder.Append("GRANT SELECT, UPDATE, INSERT, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA public TO `"$ServiceMIName`";")
        [void]$builder.Append("GRANT SELECT, UPDATE, USAGE ON ALL SEQUENCES IN SCHEMA public TO `"$ServiceMIName`";")
        [void]$builder.Append("GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO `"$ServiceMIName`";")
        [void]$builder.Append("GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO `"$ServiceMIName`";")
        return $builder.ToString()
    }

    try {

        [Environment]::SetEnvironmentVariable("PGPASSWORD", $AccessToken)

        Write-LogInfo "Checking if Principal exists in ${PostgresHost}. If not, creating Principal and granting connect permissions."
        Invoke-PSQLScript -SqlGenerator "Get-SQLScriptToCreatePrincipal"  -PostgresHost $PostgresHost -DatabaseName "postgres" -Username $DbAdminMIName
        Write-LogInfo "Script executed successfully. Principal checked/created and access granted to ${PostgresHost}."

        Write-LogInfo "Granting Writer permissions to database objects in ${DbName} for ${AdGroupDbWriter}"
        Invoke-PSQLScript -SqlGenerator "Get-SQLScriptToGrantAllPermissions" -PostgresHost $PostgresHost -DatabaseName $DbName -Username $DbAdminMIName
        Write-LogInfo "Access successfully granted to ${AdGroupDbWriter} on all database objects."

        Write-LogInfo "Granting Reader permissions to database objects in ${DbName} for ${AdGroupDbReader}"
        Invoke-PSQLScript -SqlGenerator "Get-SQLScriptToGrantReadPermissions" -PostgresHost $PostgresHost -DatabaseName $DbName -Username $DbAdminMIName
        Write-LogInfo "Read access successfully granted to database objects for ${AdGroupDbReader}"
    
        Write-LogInfo "Granting Application permissions in ${DbName} to ${ServiceMIName}"
        Invoke-PSQLScript -SqlGenerator "Get-SQLScriptToGrantApplicationPermissions" -PostgresHost $PostgresHost -DatabaseName $DbName -Username $DbAdminMIName
        Write-LogInfo "Application permissions successfully granted to ${ServiceMIName}"
    }
    finally {
        [Environment]::SetEnvironmentVariable("PGPASSWORD", $null)
    }
}

