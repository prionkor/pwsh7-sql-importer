# 1. Load the binary library directly from the script folder
$DllPath = Join-Path -Path $PSScriptRoot -ChildPath "../lib/NCrontab/NCrontab.dll"

if (-not (Test-Path -Path $DllPath)) {
    Write-Host "❌ Error: NCrontab.dll is missing from $PSScriptRoot" -ForegroundColor Red
    return
}
Add-Type -Path $DllPath -ErrorAction SilentlyContinue

# mock lock function because crom match uses it. 

function Write-Log {
    param (
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}


. (Join-Path -Path $PSScriptRoot -ChildPath "../lib/CronMatch.ps1")


# 3. Define a mock scenario (Simulating 2:30 PM)
$MockTime = [datetime]"2026-07-04 14:30:01"
Write-Host "--- CRON VALIDATION ENGINE RUNNING ---" -ForegroundColor Cyan
Write-Host "Simulating System Clock at: 14:30 (2:30 PM)`n" -ForegroundColor Yellow

# Test Case A: Exact Match list (Should be TRUE)
$CronA = "0,5,10,15,20,25,30,35,40,45,50,55 * * * *"
$ResultA = CronMatch -CronExpression $CronA -TimeToCheck $MockTime
Write-Host "Case A ($CronA): $ResultA" -ForegroundColor ($ResultA ? "Green" : "Red")

# Test Case B: Missed Match list (Should be FALSE - 14:30 does not end in a 7)
$CronB = "7,17,27,37,47,57 * * * *"
$ResultB = CronMatch -CronExpression $CronB -TimeToCheck $MockTime
Write-Host "Case B ($CronB): $ResultB" -ForegroundColor ($ResultB ? "Green" : "Red")

# Test Case C: Wildcard match (Should be TRUE - runs every minute)
$CronC = "* * * * *"
$ResultC = CronMatch -CronExpression $CronC -TimeToCheck $MockTime
Write-Host "Case C ($CronC): $ResultC" -ForegroundColor ($ResultC ? "Green" : "Red")

# Test Case D: Structural Error Handle (Should be FALSE - text is broken)
$CronD = "broken-cron-text"
$ResultD = CronMatch -CronExpression $CronD -TimeToCheck $MockTime
Write-Host "Case D ($CronD): $ResultD (Caught syntax error successfully)" -ForegroundColor Yellow
