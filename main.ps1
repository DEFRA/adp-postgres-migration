param(
    [ValidateSet("update", "rollback")]
    [string]$Command,

    [Parameter(Mandatory)]
    [string]$ChangeLogFile
)
$env:POSTGRE_HOST = "sndadpdbsps1401.postgres.database.azure.com"
$env:POSTGRE_PORT = "5432"
$env:POSTGRE_DB_NAME ="fcp-demo-claim"
$env:POSTGRE_USER = "AAG-Azure-ADP-fcp-demo-snd1-PostgresDB_Writer"
$env:PGPASSWORD = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6InE3UDFOdnh1R1F3RE4yVGFpTW92alo4YVp3cyIsImtpZCI6InE3UDFOdnh1R1F3RE4yVGFpTW92alo4YVp3cyJ9.eyJhdWQiOiJodHRwczovL29zc3JkYm1zLWFhZC5kYXRhYmFzZS53aW5kb3dzLm5ldCIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0LzZmNTA0MTEzLTZiNjQtNDNmMi1hZGU5LTI0MmUwNTc4MDAwNy8iLCJpYXQiOjE3MTg3MTk5MjEsIm5iZiI6MTcxODcxOTkyMSwiZXhwIjoxNzE4ODA2NjIxLCJhaW8iOiJFMmRnWUNqaWQzT2JmMXZTVWZkenhZd0Q3T2NtQVFBPSIsImFwcGlkIjoiMjU4OTE1MTYtZGE2Zi00MGYwLTllOGQtM2Y5MzRkNTliZGQ2IiwiYXBwaWRhY3IiOiIyIiwiaWRwIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvNmY1MDQxMTMtNmI2NC00M2YyLWFkZTktMjQyZTA1NzgwMDA3LyIsImlkdHlwIjoiYXBwIiwib2lkIjoiNzhhMjFkNDQtM2E4YS00MDFjLWE4YTctZDg3OTUwYzNhN2Q4IiwicmgiOiIwLkFUb0FFMEZRYjJScjhrT3Q2U1F1QlhnQUIxRFlQQkxmMmIxQWxOWEo4SHRfb2dNNkFBQS4iLCJzdWIiOiI3OGEyMWQ0NC0zYThhLTQwMWMtYThhNy1kODc5NTBjM2E3ZDgiLCJ0aWQiOiI2ZjUwNDExMy02YjY0LTQzZjItYWRlOS0yNDJlMDU3ODAwMDciLCJ1dGkiOiJUNE1wREpRMnUweUhJakNMSzB0UUFBIiwidmVyIjoiMS4wIiwieG1zX2lkcmVsIjoiMTAgNyJ9.B3GvA6zLBlTjSzvbV9Sq_pu5wF3gR2azXjTw5Tl7h-Qp_VnMVlrhZV2ZABDkkn1kG6Kl6SphaLs0GnILlvdJexIrV7n38FGqd4OVBYnGS--juaSuaxjJDNR4e1SRXkzLv7pp5G4Edd-qRgioIHLyFqsw-ZzFQ-AcAcHOvXdEPCX_WS6y3DAMo3oXdBUrE38Pi57sH1tf87-0uxxTLpJg2SKRgD7StX3j8oAlFKkEIbgU-lzeXhGBvXU_TvHiUlAkQKGCcNHFDC1ijp0PHyv87vpWaOqCiLuTQ1zM20Uekr4r_pAlXIYvLTDd85DUHNoazD9lNB2r1VpMBsRqJYMdGg"
$env:POSTGRE_SCHEMA = "public"
$env:SERVICE_MI_NAME = "sndadpinfmi1401-ffc-demo-claim-service"
$env:PLATFORM_MI_NAME ="sndadpinfmi1401-adp-platform-db-aad-admin"
$env:PG_WRITER_AD_GROUP="AAG-Azure-ADP-fcp-demo-snd1-PostgresDB_Writer"
$env:PG_READER_AD_GROUP="AAG-Azure-ADP-fcp-demo-snd1-PostgresDB_Reader"
$env:SYSTEM_DEBUG = "true"

function Test-EnvironmentVariables {
    $requiredVariables = @(
        "POSTGRE_HOST", 
        "POSTGRE_PORT", 
        "POSTGRE_DB_NAME", 
        "POSTGRE_SCHEMA",
        "SERVICE_MI_NAME",
        "PLATFORM_MI_NAME",
        "PG_WRITER_AD_GROUP",
        "PG_READER_AD_GROUP"
    )
    $missingVariables = $requiredVariables | Where-Object { 
        [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_)) 
    }
    if ($missingVariables.Count -gt 0) {
        Write-LogError "The following environment variables are either not set or have no value: $($missingVariables -join ', ')"
    }
}

Import-Module -Name Logger
Import-Module -Name Migration

try {

    Test-EnvironmentVariables

    Invoke-PreMigration `
        -PostgresHost $env:POSTGRE_HOST `
        -DbName $env:POSTGRE_DB_NAME `
        -DbAdminMIName $env:PLATFORM_MI_NAME `
        -ServiceMIName $env:SERVICE_MI_NAME `
        -AdGroupDbReader $env:PG_READER_AD_GROUP `
        -AdGroupDbWriter $env:PG_WRITER_AD_GROUP

    Invoke-Migration `
        -PostgreHost $env:POSTGRE_HOST `
        -PostgrePort $env:POSTGRE_PORT `
        -DbName $env:POSTGRE_DB_NAME `
        -UserName $env:POSTGRE_USER `
        -AccessToken $env:POSTGRE_PASSWORD `
        -ChangeLogFile $ChangeLogFile `
        -DefaultSchemaName $env:POSTGRE_SCHEMA `
        -Command $Command.ToLower()
    
    Invoke-PostMigration
}
catch {
    Write-LogError -Message "Migration process failed: $_"
}