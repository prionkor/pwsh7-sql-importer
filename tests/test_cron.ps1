# 1. Load the binary library directly from the script folder
$DllPath = Join-Path -Path $PSScriptRoot -ChildPath "../lib/NCrontab.dll"

if (-not (Test-Path -Path $DllPath)) {
    Write-Host "❌ Error: NCrontab.dll is missing from $PSScriptRoot" -ForegroundColor Red
    return
}
Add-Type -Path $DllPath -ErrorAction SilentlyContinue

# 2. Define the Cron function we want to validate
function Test-CronMatch {
    param (
        [string]$CronExpression,
        [datetime]$TimeToCheck = (Get-Date)
    )
    try {
        $CronSchedule = [NCrontab.CrontabSchedule]::Parse($CronExpression.Trim())
        $LookbackWindow = $TimeToCheck.AddSeconds(-1)
        $NextOccurrence = $CronSchedule.GetNextOccurrence($LookbackWindow)
        
        return (($NextOccurrence.Hour -eq $TimeToCheck.Hour) -and ($NextOccurrence.Minute -eq $TimeToCheck.Minute))
    } catch {
        return $false # Invalid cron format
    }
}

# 3. Define a mock scenario (Simulating 2:30 PM)
$MockTime = [datetime]"2026-07-04 14:30:00"
Write-Host "--- CRON VALIDATION ENGINE RUNNING ---" -ForegroundColor Cyan
Write-Host "Simulating System Clock at: 14:30 (2:30 PM)`n" -ForegroundColor Yellow

# Test Case A: Exact Match list (Should be TRUE)
$CronA = "0,5,10,15,20,25,30,35,40,45,50,55 * * * *"
$ResultA = Test-CronMatch -CronExpression $CronA -TimeToCheck $MockTime
Write-Host "Case A ($CronA): $ResultA" -ForegroundColor ($ResultA ? "Green" : "Red")

# Test Case B: Missed Match list (Should be FALSE - 14:30 does not end in a 7)
$CronB = "7,17,27,37,47,57 * * * *"
$ResultB = Test-CronMatch -CronExpression $CronB -TimeToCheck $MockTime
Write-Host "Case B ($CronB): $ResultB" -ForegroundColor ($ResultB ? "Green" : "Red")

# Test Case C: Wildcard match (Should be TRUE - runs every minute)
$CronC = "* * * * *"
$ResultC = Test-CronMatch -CronExpression $CronC -TimeToCheck $MockTime
Write-Host "Case C ($CronC): $ResultC" -ForegroundColor ($ResultC ? "Green" : "Red")

# Test Case D: Structural Error Handle (Should be FALSE - text is broken)
$CronD = "broken-cron-text"
$ResultD = Test-CronMatch -CronExpression $CronD -TimeToCheck $MockTime
Write-Host "Case D ($CronD): $ResultD (Caught syntax error successfully)" -ForegroundColor Yellow
