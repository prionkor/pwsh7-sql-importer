function SleepUntilNextMinute {

    $Now = Get-Date

    $NextMinute = $Now.AddMinutes(1)

    $NextMinute = Get-Date `
        -Year   $NextMinute.Year `
        -Month  $NextMinute.Month `
        -Day    $NextMinute.Day `
        -Hour   $NextMinute.Hour `
        -Minute $NextMinute.Minute `
        -Second 0

    $SleepSeconds = ($NextMinute - $Now).TotalSeconds

    if ($SleepSeconds -gt 0) {
        Start-Sleep -Seconds ([math]::Ceiling($SleepSeconds))
    }
}