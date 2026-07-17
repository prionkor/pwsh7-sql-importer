param(
    [switch]$Scheduled
)

# ==============================================================================
# --- IMPORT MODULES EXTENSIONS ---
# ==============================================================================

. (Join-Path -Path $PSScriptRoot -ChildPath "lib/CronMatch.ps1")
. (Join-Path -Path $PSScriptRoot -ChildPath "lib/Get-EnvOrThrow.ps1")
. (Join-Path -Path $PSScriptRoot -ChildPath "lib/Import-DotEnv.ps1")
. (Join-Path -Path $PSScriptRoot -ChildPath "lib/Write-Log.ps1")
. (Join-Path -Path $PSScriptRoot -ChildPath "lib/ShouldRunTask.ps1")
. (Join-Path -Path $PSScriptRoot -ChildPath "lib/Export-TaskData.ps1")
. (Join-Path -Path $PSScriptRoot -ChildPath "lib/Send-Email.ps1")
. (Join-Path -Path $PSScriptRoot -ChildPath "lib/Initialize-Config.ps1")
. (Join-Path -Path $PSScriptRoot -ChildPath "lib/Mine.ps1")

Import-DotEnv -Path (Join-Path $PSScriptRoot ".env")

# ==============================================================================
# --- CONFIGURATION AND CORE MODULE LOADING LAYER ---
# ==============================================================================

Initialize-Config -ProjectRoot $PSScriptRoot -IsScheduledRun:$Scheduled

$DllPath = Join-Path -Path $PSScriptRoot -ChildPath "lib/NCrontab/NCrontab.dll"

if (-not (Test-Path -Path $DllPath -PathType Leaf)) {
    Write-Log "DLL Path $($DllPath) not found" "INFO"
    throw "Required assembly not found: $DllPath"
}

try {
    Add-Type -Path $DllPath -ErrorAction Stop
}
catch {
    Write-Log "Failed to load required assembly '$DllPath'. $($_.Exception.Message)"
    throw "Failed to load required assembly '$DllPath'. $($_.Exception.Message)"
}

# ==============================================================================
# --- DIRECTORY CREATION ---
# ==============================================================================

$Folders = @(
    $global:Config.QueriesDir
    $global:Config.DataDir
    (Split-Path -Path $global:Config.LogFile -Parent)
)

foreach ($f in $Folders) { 
    if (-not (Test-Path -Path $f -PathType Container)) {
        New-Item -Path $f -ItemType Directory -Force | Out-Null
    }
}

# ==============================================================================
# --- Log File Maintenance ---
# ==============================================================================
if (
    (Test-Path -Path $global:Config.LogFile -PathType Leaf) -and
    ((Get-Item -Path $global:Config.LogFile).Length -gt 5MB)
) {
    Remove-Item -Path $global:Config.LogFile
}

# Task File Check
if (-not (Test-Path $global:Config.TaskFile -PathType Leaf)) {
    Write-Log "Tasks file missing. Creating template." "INFO"
    "TaskName,QueryFile,TestMode,RunWindow,CronString,EmailTo,SaveTo,SavePath`n" | Out-File $global:Config.TaskFile -Encoding utf8
    Write-Log "Created tasks file. No task to run." "INFO"
    return
}

Mine