Import-Module -Name Logger
Import-Module -Name Migration

try {
    Invoke-PreMigration
    Invoke-Migration
    Invoke-PostMigration
}
catch {
    Write-Log -Message "Migration process failed: $_" -Level "ERROR"
}