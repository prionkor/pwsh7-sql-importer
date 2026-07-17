. (Join-Path -Path $PSScriptRoot -ChildPath "lib/Sleep-UntilNextMinute.ps1")

$MinerScript = Join-Path $PSScriptRoot "miner.ps1"
$Pwsh = (Get-Command pwsh).Source

# This function pushes the sleep until the next :00 second mark, 
# so that the miner script runs at the start of each minute.
SleepUntilNextMinute

while ($true) {
    Start-Process $Pwsh `
    -ArgumentList @(
        "-NoProfile"
        "-ExecutionPolicy", "Bypass"
        "-File", $MinerScript
        "-Scheduled"
    )
    SleepUntilNextMinute
}