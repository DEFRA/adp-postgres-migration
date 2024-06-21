function Invoke-Migration {
    param(
        [Parameter(Mandatory=$false)][securestring]$AUTH_CLIENT_ID
    )

     Write-Log -Message "Migration: Hello, World!" -Level "INFO"
}