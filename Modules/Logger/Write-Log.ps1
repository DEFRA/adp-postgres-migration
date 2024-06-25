function Write-FormatedMessage {
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$Color,
        [string]$Level
    )

    # Define ANSI color codes
    $colors = @{
        "Cyan" = "`e[36m"
        "Red" = "`e[31m"
        "Blue" = "`e[34m"
        "Yellow" = "`e[33m"
        "Default" = "`e[0m" 
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = @{
        Timestamp = $timestamp
        Level = $Level
        Message = $Message
    }
    $colorCode = $null -ne $colors[$Color] ? $colors[$Color] : $colors["Default"]
    $resetCode = $colors["Default"]
    
    Write-Host ($colorCode + ($logEntry | ConvertTo-Json -Compress) + $resetCode)
}

function Write-LogInfo {
    param([Parameter(Mandatory)][string]$Message)
    Write-FormatedMessage -Message $Message -Color Cyan -Level "info"
}

function Write-LogError {
    param([Parameter(Mandatory)][string]$Message)
    Write-FormatedMessage -Message $Message -Color Red -Level "error"
    exit -1
}

function Write-LogDebug {
    param([Parameter(Mandatory)][string]$Message)
    if ((Test-Path -Path env:SYSTEM_DEBUG) -and ($env:SYSTEM_DEBUG -eq "true")) {
        Write-FormatedMessage -Message $Message -Color Blue -Level "debug"
    }
}

function Write-LogWarning {
    param([Parameter(Mandatory)][string]$Message)
    Write-FormatedMessage -Message $Message -Color Yellow -Level "warning"
}