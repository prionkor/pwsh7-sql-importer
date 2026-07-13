# Logger Function
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Stamp] [$Level] $Message"
    
    # Save to file
    $LogEntry | Out-File -FilePath $global:Config.LogFile -Append
    
    # Determine color logic
    $Color = "Cyan"
    if ($Level -eq "ERROR") { $Color = "Red" }
    if ($Level -eq "SUCCESS") { $Color = "Green" }

    # Output to console
    Write-Host $LogEntry -ForegroundColor $Color
}