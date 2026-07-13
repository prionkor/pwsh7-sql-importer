function CronMatch {
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
        Write-Log "Task '$TaskName' has an invalid CronString '$CronExpression'. The task will be skipped." "INFO"
        return $false 
    }
}