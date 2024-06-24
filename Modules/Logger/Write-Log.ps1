function Write-FormatedMessage {
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$Color,
        [string]$Level
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntryString = "[$timestamp] [$Level] $Message"
    Write-Host $logEntryString -ForegroundColor $Color
}

function Write-LogInfo {
    param([Parameter(Mandatory)][string]$Message)
    Write-FormatedMessage -Message $Message -Color Cyan -Level "INFO"
}

function Write-LogError {
    param([Parameter(Mandatory)][string]$Message)
    Write-FormatedMessage -Message $Message -Color Red -Level "ERROR"
    exit -1
}

function Write-LogDebug {
    param([Parameter(Mandatory)][string]$Message)
    if ((Test-Path -Path env:SYSTEM_DEBUG) -and ($env:SYSTEM_DEBUG -eq "true")) {
        Write-FormatedMessage -Message $Message -Color Blue -Level "DEBUG"
    }
}

function Write-LogWarning {
    param([Parameter(Mandatory)][string]$Message)
    Write-FormatedMessage -Message $Message -Color Yellow -Level "WARNING"
}