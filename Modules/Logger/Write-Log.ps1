function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR")][string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntryString = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        "INFO" {
            Write-Host $logEntryString -ForegroundColor Cyan
        }
        "WARNING" {
            Write-Host $logEntryString -ForegroundColor Yellow
        }
        "ERROR" {
            Write-Host $logEntryString -ForegroundColor Red
            exit 1
        }
    }
}