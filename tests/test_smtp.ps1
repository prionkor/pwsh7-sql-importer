. (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath "lib/Import-DotEnv.ps1")
. (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath "lib/Initialize-Config.ps1")

# Import the environment variables
$EnvPath = Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath ".env"
Import-DotEnv -Path $EnvPath

# Initialize the configuration
Initialize-Config -ProjectRoot (Join-Path -Path $PSScriptRoot -ChildPath "..") -IsScheduledRun $false

# Dot-source the scripts using the execution operator correctly
. (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath "lib/Send-Email.ps1")


# Send the test email
Send-Email -To "prionkor.business@gmail.com" -Subject "Test Email from PowerShell" -Body "This is a test email sent from PowerShell."
