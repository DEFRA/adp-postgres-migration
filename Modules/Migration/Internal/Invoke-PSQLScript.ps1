function Invoke-PSQLScript {
    param (
        [string]$SqlGenerator,
        [string]$PostgresHost,
        [string]$DatabaseName,
        [string]$Username
    )
    try {

        $tempFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFile -Value (&$SqlGenerator) -Force

        Write-LogInfo "Executing SQL script on ${PostgresHost} for database ${DatabaseName} with username ${Username}"
        Write-LogDebug "SQL script content: $(Get-Content -Path $tempFile)"
        
        $null = Invoke-Expression "psql -A -q -h $PostgresHost -U $Username $DatabaseName -f '$($tempFile)'"
        if ($LASTEXITCODE -ne 0) {
            Write-LogError "SQL script execution failed with error code: $LASTEXITCODE."
        }
        
    }
    catch {
        throw $_
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
    }
}

