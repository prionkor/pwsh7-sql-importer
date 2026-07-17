. (Join-Path -Path $PSScriptRoot -ChildPath "lib/Sleep-UntilNextMinute.ps1")

$MinerScript = Join-Path $PSScriptRoot "miner.ps1"
$Pwsh = (Get-Command pwsh).Source

$LogDir = Join-Path $PSScriptRoot "logs"

$StdOut = Join-Path $LogDir "miner.out.log"
$StdErr = Join-Path $LogDir "miner.err.log"


# This function pushes the sleep until the next :00 second mark, 
# so that the miner script runs at the start of each minute.
SleepUntilNextMinute

while ($true) {
    $Process = Start-Process $Pwsh `
    -ArgumentList @(
        "-NoProfile"
        "-ExecutionPolicy", "Bypass"
        "-File", "`"$MinerScript`""
        "-Scheduled"
    ) `
    -RedirectStandardOutput $StdOut `
    -RedirectStandardError  $StdErr `
    -PassThru

    # stdout the pid
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Started miner.ps1 with PID: $($Process.Id)" -ForegroundColor Green
    SleepUntilNextMinute
}