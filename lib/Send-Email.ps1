. (Join-Path -Path $PSScriptRoot -ChildPath "Write-Log.ps1")


function Send-Email {
    param(
        [Parameter(Mandatory)]
        [string]$To,

        [Parameter(Mandatory)]
        [string]$Subject,

        [Parameter(Mandatory)]
        [string]$Body,

        [string]$AttachmentPath
    )

    switch ($global:Config.Email.Provider) {
        "smtp" {
            Send-Email-SMTP -To $To -Subject $Subject -Body $Body -AttachmentPath $AttachmentPath
        } "azure" {
            Send-Email-Azure -To $To -Subject $Subject -Body $Body -AttachmentPath $AttachmentPath
        } default {
            Write-Log "Unsupported email provider: $($global:Config.Email.Provider)" "ERROR"
            throw "Unsupported email provider: $($global:Config.Email.Provider)"
        }
    }
}

function Send-Email-SMTP {
    param(
        [Parameter(Mandatory)]
        [string]$To,

        [Parameter(Mandatory)]
        [string]$Subject,

        [Parameter(Mandatory)]
        [string]$Body,

        [string]$AttachmentPath
    )

    try {
        $MailMessage = [System.Net.Mail.MailMessage]::new()

        # Sender
        $MailMessage.From = [System.Net.Mail.MailAddress]::new($global:Config.Email.From)

        # Recipients (comma separated)
        foreach ($Recipient in ($To -split ',')) {  
            $Recipient = $Recipient.Trim()
            if ($Recipient) {
                $MailMessage.To.Add($Recipient)
            }
        }

        $MailMessage.Subject = $Subject
        $MailMessage.Body = $Body
        $MailMessage.IsBodyHtml = $false

        # Optional attachment
        if (-not [string]::IsNullOrWhiteSpace($AttachmentPath)) {
            if (-not (Test-Path -Path $AttachmentPath -PathType Leaf)) {
                throw "Attachment file not found: $AttachmentPath"
            }

            $Attachment = [System.Net.Mail.Attachment]::new($AttachmentPath)
            $MailMessage.Attachments.Add($Attachment)
        }

        $SmtpClient = [System.Net.Mail.SmtpClient]::new(
            $global:Config.SMTP.Host,
            [int]$global:Config.SMTP.Port
        )

        $SmtpClient.EnableSsl = [bool]$global:Config.SMTP.EnableSsl
        $SmtpClient.Credentials = [System.Net.NetworkCredential]::new(
            $global:Config.SMTP.User,
            $global:Config.SMTP.Pass
        )

        $SmtpClient.Send($MailMessage)

        Write-Log "Email sent successfully to [$To]." "SUCCESS"
    }
    catch {
        Write-Log "Failed to send email to [$To]: $($_.Exception.Message)" "ERROR"
        throw
    }
    finally {
        if ($Attachment) {
            $Attachment.Dispose()
        }

        if ($MailMessage) {
            $MailMessage.Dispose()
        }

        if ($SmtpClient) {
            $SmtpClient.Dispose()
        }
    }
}

function Send-Email-Azure {
    param(
        [Parameter(Mandatory)]
        [string]$To,

        [Parameter(Mandatory)]
        [string]$Subject,

        [Parameter(Mandatory)]
        [string]$Body,

        [string]$AttachmentPath
    )

    try {

        # Build recipients
        $Recipients = @()

        foreach ($Recipient in ($To -split ',')) {
            $Recipient = $Recipient.Trim()

            if ($Recipient) {
                $Recipients += @{
                    address = $Recipient
                }
            }
        }

        # Build request body
        $RequestBody = @{
            senderAddress = $global:Config.Email.From
            content = @{
                subject   = $Subject
                plainText = $Body
            }
            recipients = @{
                to = $Recipients
            }
        }

        # Optional attachment
        if (-not [string]::IsNullOrWhiteSpace($AttachmentPath)) {

            if (-not (Test-Path -Path $AttachmentPath -PathType Leaf)) {
                throw "Attachment file not found: $AttachmentPath"
            }

            $AttachmentBytes = [System.IO.File]::ReadAllBytes($AttachmentPath)

            $RequestBody.attachments = @(
                @{
                    name = [System.IO.Path]::GetFileName($AttachmentPath)
                    contentType = Get-MimeType -Path $AttachmentPath
                    contentInBase64 = [Convert]::ToBase64String($AttachmentBytes)
                }
            )
        }

        $Json = $RequestBody | ConvertTo-Json -Depth 10

        $Headers = @{
            "Content-Type" = "application/json"
        }

        Invoke-RestMethod `
            -Method POST `
            -Uri "$($global:Config.AzureEmail.Endpoint)/emails:send?api-version=2023-03-31" `
            -Headers $Headers `
            -Body $Json

        Write-Log "Email sent successfully to [$To]." "SUCCESS"
    }
    catch {
        Write-Log "Failed to send email to [$To]: $($_.Exception.Message)" "ERROR"
        throw
    }
}