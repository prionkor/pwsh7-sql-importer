function Export-TaskData {
    param (
        [pscustomobject]$Task,
        [string]$SqlFile,
        [datetime]$CurrentTime
    )

    $Result = [PSCustomObject]@{
        Success    = $false
        OutputFile = $null
        Message    = $null
    }

    $SqlQuery = Get-Content -Path $SqlFile -Raw

    $TaskDataDir = Join-Path -Path $global:Config.DataDir -ChildPath $Task.TaskName

    if (-not (Test-Path -Path $TaskDataDir -PathType Container)) {
        New-Item -Path $TaskDataDir -ItemType Directory | Out-Null
    }

    $HeaderOutFile = Join-Path $TaskDataDir "_headers.tmp"
    $DataOutFile   = Join-Path $TaskDataDir "_data.tmp"

    $FileName = "{0:yyyy-MM-dd HH-mm}.csv" -f $CurrentTime
    $CurrentOutFile = Join-Path $TaskDataDir $FileName

    try {

        # ------------------------------------------------------------------
        # STEP 1 - Extract column headers
        # ------------------------------------------------------------------

        Write-Log "Extracting column headers for [$($Task.TaskName)]..."

        $EscapedQuery = $SqlQuery.Replace("'", "''")

        $HeaderQuery = @"
SET NOCOUNT ON;
SELECT STRING_AGG(name, ',')
WITHIN GROUP (ORDER BY column_ordinal)
FROM sys.dm_exec_describe_first_result_set(
    N'$EscapedQuery',
    NULL,
    0
);
"@

        $HeaderArgs = @(
            "-S", $global:Config.DB.Host,
            "-d", $global:Config.DB.Name,
            "-U", $global:Config.DB.User,
            "-P", $global:Config.DB.Pass,
            "-Q", $HeaderQuery,
            "-h", "-1",
            "-W",
            "-o", $HeaderOutFile
        )

        & $global:Config.SqlCmdPath @HeaderArgs

        if (
            (-not (Test-Path -Path $HeaderOutFile -PathType Leaf)) -or
            ((Get-Content -Path $HeaderOutFile -Raw).Trim() -eq "")
        ) {
            $Result.Message = "Header extraction failed for task [$($Task.TaskName)]."
            $Result.Success = $false
            return $Result
        }

        $CleanHeader = Get-Content -Path $HeaderOutFile |
            Where-Object {
                $_ -notmatch '^Sqlcmd:' -and
                $_.Trim() -ne ''
            }

        if (-not $CleanHeader) {
            $Result.Message = "Header file was empty after cleaning for task [$($Task.TaskName)]."
            $Result.Success = $false
            return $Result
        }

        $CleanHeader | Set-Content $HeaderOutFile

        # ------------------------------------------------------------------
        # STEP 2 - Export data
        # ------------------------------------------------------------------

        Write-Log "Extracting data rows for [$($Task.TaskName)]..."

        $BcpArgs = @(
            $SqlQuery,
            "queryout",
            $DataOutFile,
            "-S", "$($global:Config.DB.Host);Encrypt=No",
            "-d", $global:Config.DB.Name,
            "-U", $global:Config.DB.User,
            "-P", $global:Config.DB.Pass,
            "-c",
            "-t", ",",
            "-C"
        )

        & $global:Config.BcpPath @BcpArgs

        if (
            ($LASTEXITCODE -ne 0) -or
            (-not (Test-Path -Path $DataOutFile -PathType Leaf))
        ) {
            $Result.Message = "BCP failed for task [$($Task.TaskName)] (Exit Code: $LASTEXITCODE)."
            $Result.Success = $false
            return $Result
        }

        # ------------------------------------------------------------------
        # STEP 3 - Merge header and data
        # ------------------------------------------------------------------

        Get-Content $HeaderOutFile, $DataOutFile |
            Set-Content $CurrentOutFile

        $Result.Message = "Export completed successfully: $CurrentOutFile"
        $Result.Success = $true
        $Result.OutputFile = $CurrentOutFile
        return $Result
    }
    finally {
        Remove-Item $HeaderOutFile -ErrorAction SilentlyContinue
        Remove-Item $DataOutFile   -ErrorAction SilentlyContinue
    }
}