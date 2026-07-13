function Get-MimeType {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        ".csv"  { "text/csv" }
        ".txt"  { "text/plain" }
        ".pdf"  { "application/pdf" }
        ".json" { "application/json" }
        ".xml"  { "application/xml" }
        ".zip"  { "application/zip" }
        ".jpg"  { "image/jpeg" }
        ".jpeg" { "image/jpeg" }
        ".png"  { "image/png" }
        ".gif"  { "image/gif" }
        ".xlsx" { "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
        ".xls"  { "application/vnd.ms-excel" }
        default { "application/octet-stream" }
    }
}