function Invoke-Migration {
    param(
        [Parameter(Mandatory = $false)][securestring]$AUTH_CLIENT_ID
    )

    Set-StrictMode -Version Latest

    if ($env:INSTALL_MYSQL) {
        lpm add mysql --global
    }

    if ($args[0] -ne "history" -and $args[0] -ne "init" -and (Get-Command $args[0] -ErrorAction SilentlyContinue)) {
        & $args
    }
    else {
        if ($args -join " " -match "--defaultsFile" -or $args -join " " -match "--defaults-file" -or $args -join " " -match "--version") {
            & "/liquibase/liquibase" $args
        }
        else {
            & "/liquibase/liquibase" "--defaultsFile=/liquibase/liquibase.docker.properties" $args
        }
    }

}