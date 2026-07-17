function Get-TaskLock {
    param(
        [Parameter(Mandatory)]
        [string]$TaskName
    )

    $LockFile = Join-Path $global:Config.DataDir "$TaskName.lock"

    try {
        $Stream = [System.IO.File]::Open(
            $LockFile,
            [System.IO.FileMode]::CreateNew,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::None
        )

        try {
            $LockInfo = @{
                PID     = $PID
                Started = Get-Date
                Task    = $TaskName
            } | ConvertTo-Json

            $Bytes = [System.Text.Encoding]::UTF8.GetBytes($LockInfo)
            $Stream.Write($Bytes, 0, $Bytes.Length)
        }
        finally {
            $Stream.Dispose()
        }

        return $LockFile
    }
    catch [System.IO.IOException] {
        # Lock already exists
        return $null
    }
}