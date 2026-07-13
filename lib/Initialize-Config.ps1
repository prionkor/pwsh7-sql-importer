function Initialize-Config {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,

        [Parameter(Mandatory)]
        [bool]$IsScheduledRun
    )

    $global:Config = @{
        DB = @{
            Host = Get-EnvOrThrow -Name "DB_HOST"
            Name = Get-EnvOrThrow -Name "DB_NAME"
            User = Get-EnvOrThrow -Name "DB_USER"
            Pass = Get-EnvOrThrow -Name "DB_PASS"
        }
        IsScheduledRun  = $IsScheduledRun
        TaskFile        = Join-Path -Path $ProjectRoot -ChildPath "tasks.csv"
        QueriesDir      = Join-Path -Path $ProjectRoot -ChildPath "queries"
        DataDir         = Join-Path -Path $ProjectRoot -ChildPath "data"
        LogFile         = Join-Path -Path $ProjectRoot -ChildPath "logs" -AdditionalChildPath "sync.log"

        BcpPath      = Get-EnvOrThrow -Name "BCP_PATH"
        SqlCmdPath   = Get-EnvOrThrow -Name "SQL_CMD_PATH"

        SMTP = @{
            Host = Get-EnvOrThrow "SMTP_HOST"
            Port = Get-EnvOrThrow "SMTP_PORT"
            User = Get-EnvOrThrow "SMTP_USER"
            Pass = Get-EnvOrThrow "SMTP_PASS"
            EnableSsl = [bool]::Parse((Get-EnvOrThrow "SMTP_SSL"))
        }
        Email = @{
            Provider = Get-EnvOrThrow "EMAIL_PROVIDER"
            MaxAttachmentSize = 10MB
            From = Get-EnvOrThrow "EMAIL_FROM"
        }
        ACS = @{ 
            Key = Get-EnvOrThrow "ACS_KEY"
            Endpoint = Get-EnvOrThrow "ACS_ENDPOINT"
        }
    }
}
