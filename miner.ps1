
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

$DllPath = Join-Path -Path $PSScriptRoot -ChildPath "lib/NCrontab/NCrontab.dll"

if (-not (Test-Path -Path $DllPath -PathType Leaf)) {
    throw "Required assembly not found: $DllPath"
}

try {
    Add-Type -Path $DllPath -ErrorAction Stop
}
catch {
    throw "Failed to load required assembly '$DllPath'. $($_.Exception.Message)"
}

Import-DotEnv -Path (Join-Path $PSScriptRoot ".env")

# ==============================================================================
# --- CONFIGURATION AND CORE MODULE LOADING LAYER ---
# ==============================================================================

param(
    [switch]$Scheduled
)

Initialize-Config -ProjectRoot $PSScriptRoot -IsScheduledRun:$Scheduled

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
    "TaskName,QueryFile,TestMode,RunWindow,CronString,SaveTo,SavePath`n" | Out-File $global:Config.TaskFile -Encoding utf8
    Write-Log "Created tasks file. No task to run." "INFO"
    return
}

$Tasks = Import-Csv -Path $global:Config.TaskFile
$Now = Get-Date

$TasksToRun = @()
foreach ($Task in $Tasks) {
    if (ShouldRunTask -Task $Task -IsScheduledRun $global:Config.IsScheduledRun -CurrentTime $Now) {
        $TasksToRun += $Task
    }
}

foreach ($Task in $TasksToRun) {
    $TargetSqlFile = Join-Path $global:Config.QueriesDir $Task.QueryFile

    if (-not (Test-Path -Path $TargetSqlFile -PathType Leaf)) {
        Write-Log "Skipping task [$($Task.TaskName)]: SQL file not found: $TargetSqlFile" "ERROR"
        continue
    }

    $Result = Export-TaskData `
        -Task $Task `
        -SqlFile $TargetSqlFile `
        -CurrentTime $Now

    Write-Log $Result.Message $Result.Success ? "SUCCESS" : "ERROR"

    if ($Result.Success -and $Task.EmailTo) {
        $EmailBody = "Task [$($Task.TaskName)] completed successfully at $($Now.ToString("yyyy-MM-dd HH:mm:ss"))."
        $IsFileTooLarge = (Get-Item $CurrentOutFile).Length -gt $global:Config.Email.MaxAttachmentSize

        if ($IsFileTooLarge) {
            $SizeMB = [math]::Round($global:Config.Email.MaxAttachmentSize / 1MB, 2)
            Write-Log "File exceeds email attachment limit of ($SizeMB MB)." "INFO"
            $EmailBody += " The report file was generated successfully, but it exceeds the maximum attachment size ($SizeMB MB). Please download it from data directory."
        }

        if (-not $IsFileTooLarge) {
            Send-Email `
                -To $Task.EmailTo `
                -Subject $Subject `
                -Body $Body `
                -AttachmentPath $CurrentOutFile
        } else {
            Send-Email `
                -To $Task.EmailTo `
                -Subject $Subject `
                -Body $Body
        }
    }

}
