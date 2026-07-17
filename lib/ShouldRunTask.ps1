. (Join-Path -Path $PSScriptRoot -ChildPath "CronMatch.ps1")

function ShouldRunTask {
    param (
        [pscustomobject]$Task,
        [bool]$IsScheduledRun,
        [datetime]$CurrentTime = (Get-Date)
    )

    # Task validation
    if ([string]::IsNullOrWhiteSpace($Task.TaskName)) {
        Write-Log "Skipping task: TaskName is missing." "INFO"
        return $false
    }

    if ([string]::IsNullOrWhiteSpace($Task.QueryFile)) {
        Write-Log "Skipping task '$($Task.TaskName)': No query file specified." "INFO"
        return $false
    }

    # Normalize values
    $TestMode  = $Task.TestMode.Trim().ToLowerInvariant()
    $RunWindow = $Task.RunWindow.Trim()
    $Cron      = "$($Task.CronString)".Trim()

    # Manual execution: only run test tasks
    if (-not $IsScheduledRun) {
        return ($TestMode -eq "yes")
    }

    # Scheduled execution: ignore test tasks
    if ($TestMode -eq "yes") {
        # Write-Log "Skipping task '$($Task.TaskName)': TestMode is enabled during scheduled run." "INFO"
        return $false
    }

    # Cron schedule takes precedence
    if ($Cron) {
        return (CronMatch -CronExpression $Cron -TimeToCheck $CurrentTime)
    }

    # Fall back to simple daily schedule
    if ($RunWindow) {
        return ($CurrentTime.ToString("HH:mm") -eq $RunWindow)
    }

    # No valid schedule
    Write-Log "Skipping task '$($Task.TaskName)': No valid RunWindow or CronString specified." "INFO"
    return $false
}