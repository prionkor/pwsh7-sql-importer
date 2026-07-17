function Mine{
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

        # Write a lock file if not exists
        $LockFile = Get-TaskLock -TaskName $Task.TaskName
        if (-not $LockFile) {
            Write-Log "Task '$($Task.TaskName)' already running." "INFO"
            continue
        }

        try{
            $Result = Export-TaskData `
                -Task $Task `
                -SqlFile $TargetSqlFile `
                -CurrentTime $Now

            Write-Log $Result.Message $Result.Success ? "SUCCESS" : "ERROR"

            if ($Result.Success -and $Task.EmailTo) {
                $Subject = "Data Mining Task $($Task.TaskName) Completed"
                $EmailBody = "Task [$($Task.TaskName)] completed successfully at $($Now.ToString("yyyy-MM-dd HH:mm:ss"))."
                $IsFileTooLarge = (Get-Item $Result.OutputFile).Length -gt $global:Config.Email.MaxAttachmentSize

                if ($IsFileTooLarge) {
                    $SizeMB = [math]::Round($global:Config.Email.MaxAttachmentSize / 1MB, 2)
                    Write-Log "File exceeds email attachment limit of ($SizeMB MB)." "INFO"
                    $EmailBody += " The report file was generated successfully, but it exceeds the maximum attachment size ($SizeMB MB). Please download it from data directory."
                }

                if (-not $IsFileTooLarge) {
                    Send-Email `
                        -To $Task.EmailTo `
                        -Subject $Subject `
                        -Body $EmailBody `
                        -AttachmentPath $Result.OutputFile
                } else {
                    Send-Email `
                        -To $Task.EmailTo `
                        -Subject $Subject `
                        -Body $EmailBody
                }
            }
        }finally{
            Remove-Item $LockFile -Force -ErrorAction SilentlyContinue
        }
    }
}