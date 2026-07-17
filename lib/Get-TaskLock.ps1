function Get-TaskLock {
    param(
        [Parameter(Mandatory)]
        [string]$TaskName
    )

    $LockFile = Join-Path -Path $global:Config.DataDir -ChildPath "$TaskName.lock"

    try {
        # Atomically acquire the lock. If the file already exists,
        # another worker owns the lock.
        New-Item `
            -Path $LockFile `
            -ItemType File `
            -ErrorAction Stop | Out-Null

        @{
            PID     = $PID
            Started = Get-Date
            Task = $TaskName
        } |
        ConvertTo-Json |
        Set-Content `
            -Path $LockFile `
            -Encoding utf8 `
            -ErrorAction Stop

        return $LockFile
    }
    catch {
        # If writing metadata failed, don't leave a stale lock behind.
        if (Test-Path -Path $LockFile -PathType Leaf) {
            Remove-Item `
                -Path $LockFile `
                -Force `
                -ErrorAction SilentlyContinue
        }

        return $null
    }
}