function Import-DotEnv {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw "The specified .env file does not exist: $Path"
    }

    foreach ($Line in Get-Content -Path $Path) {

        $Line = $Line.Trim()

        # Skip blank lines and comments
        if ([string]::IsNullOrWhiteSpace($Line) -or $Line.StartsWith("#")) {
            continue
        }

        # Split only on the first '='
        $Parts = $Line -split '=', 2

        if ($Parts.Count -ne 2) {
            Write-Log "Ignoring invalid .env entry: $Line" "INFO"
            continue
        }

        $Name  = $Parts[0].Trim()
        $Value = $Parts[1].Trim()

        # Remove matching surrounding quotes
        if (
            ($Value.StartsWith('"') -and $Value.EndsWith('"')) -or
            ($Value.StartsWith("'") -and $Value.EndsWith("'"))
        ) {
            $Value = $Value.Substring(1, $Value.Length - 2)
        }

        # Skip invalid variable names
        if ([string]::IsNullOrWhiteSpace($Name)) {
            Write-Log "Ignoring invalid .env entry with empty variable name." "INFO"
            continue
        }

        # Do not overwrite existing environment variables
        $ExistingValue = [Environment]::GetEnvironmentVariable($Name, "Process")

        if ([string]::IsNullOrWhiteSpace($ExistingValue)) {
            [Environment]::SetEnvironmentVariable($Name, $Value, "Process")
        } else {
            Write-Log "Skipping .env variable '$Name' because it is already defined in the environment." "INFO"
        }
    }
}
function Get-EnvOrThrow {
    param([string]$Name)

    $Value = [Environment]::GetEnvironmentVariable($Name)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "Required environment variable '$Name' is not set."
    }

    return $Value
}