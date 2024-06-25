function Grant-PostgresDBScheamAccess {
    param (
        [Parameter(Mandatory)]    
        [string]$PostgresHost,

        [Parameter(Mandatory)]
        [string]$DbName,

        [Parameter(Mandatory)]
        [string]$DbUserName,

        [Parameter(Mandatory)]
        [string]$ServiceMIName,

        [Parameter(Mandatory)]
        [string]$AccessToken,

        [Parameter(Mandatory)]
        [string]$AdGroupDbReader
    )

    function Get-SQLScriptToGrantReadPermissions {
        [System.Text.StringBuilder]$builder = [System.Text.StringBuilder]::new()
        [void]$builder.Append("GRANT USAGE ON SCHEMA public TO `"$AdGroupDbReader`";")
        [void]$builder.Append("GRANT SELECT ON ALL TABLES IN SCHEMA public TO `"$AdGroupDbReader`";")
        [void]$builder.Append("GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO `"$AdGroupDbReader`";")
        [void]$builder.Append("REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM `"$AdGroupDbReader`";")
        [void]$builder.Append("REVOKE EXECUTE ON ALL PROCEDURES IN SCHEMA public FROM `"$AdGroupDbReader`";")
        [void]$builder.Append("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO `"$AdGroupDbReader`";")
        [void]$builder.Append("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO `"$AdGroupDbReader`";")
        [void]$builder.Append("ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM `"$AdGroupDbReader`";")
        return $builder.ToString()
    }

    function Get-SQLScriptToGrantApplicationPermissions {
        [System.Text.StringBuilder]$builder = [System.Text.StringBuilder]::new()
        [void]$builder.Append("GRANT CREATE, USAGE ON SCHEMA public TO `"$ServiceMIName`";")
        [void]$builder.Append("GRANT SELECT, UPDATE, INSERT, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA public TO `"$ServiceMIName`";")
        [void]$builder.Append("GRANT SELECT, UPDATE, USAGE ON ALL SEQUENCES IN SCHEMA public TO `"$ServiceMIName`";")
        [void]$builder.Append("GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO `"$ServiceMIName`";")
        [void]$builder.Append("GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO `"$ServiceMIName`";")
        [void]$builder.Append("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, UPDATE, INSERT, REFERENCES, TRIGGER ON TABLES TO `"$ServiceMIName`";")
        [void]$builder.Append("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO `"$ServiceMIName`";")
        [void]$builder.Append("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO `"$ServiceMIName`";")
        return $builder.ToString()
    }

    try {
        [Environment]::SetEnvironmentVariable("PGPASSWORD", $AccessToken)

        Write-LogInfo "Granting Reader permissions to database objects in ${DbName} for ${AdGroupDbReader}"
        Invoke-PSQLScript -SqlGenerator "Get-SQLScriptToGrantReadPermissions"  -PostgresHost $PostgresHost -DatabaseName $DbName -Username $DbUserName
        Write-LogInfo "Read access successfully granted to database objects for ${AdGroupDbReader}"

        Write-LogInfo "Granting Application permissions in ${DbName} to ${ServiceMIName}"
        Invoke-PSQLScript -SqlGenerator "Get-SQLScriptToGrantApplicationPermissions"  -PostgresHost $PostgresHost -DatabaseName $DbName -Username $DbUserName
        Write-LogInfo "Application permissions successfully granted to ${ServiceMIName}"
    }
    finally {
        [Environment]::SetEnvironmentVariable("PGPASSWORD", $null)
    }

}