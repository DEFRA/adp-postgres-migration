Import-Module -Name Logger

try {
    Invoke-PreMigration
    Invoke-Migration
    Invoke-PostMigration
}
catch {
    Write-Log -Message "Migration process failed: $_" -Level "ERROR"
} 