
function CronMatch {
    param (
        [Parameter(Mandatory)]
        [string]$CronExpression,

        [datetime]$TimeToCheck = (Get-Date)
    )

    try {
        $CronSchedule = [NCrontab.CrontabSchedule]::Parse($CronExpression.Trim())

        # Normalize to the beginning of the current minute
        $CurrentMinute = [datetime]::new(
            $TimeToCheck.Year,
            $TimeToCheck.Month,
            $TimeToCheck.Day,
            $TimeToCheck.Hour,
            $TimeToCheck.Minute,
            0,
            $TimeToCheck.Kind
        )

        # Ask for the first occurrence immediately after the previous instant
        $PreviousInstant = $CurrentMinute.AddTicks(-1)

        $NextOccurrence = $CronSchedule.GetNextOccurrence($PreviousInstant)

        return ($NextOccurrence -eq $CurrentMinute)
    }
    catch {
        Write-Log "Invalid CronString '$CronExpression'. Task will be skipped." "ERROR"
        return $false
    }
}