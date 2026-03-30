# Foxit eSign - Send Document for Signature
# Usage: .\send-foxit-esign.ps1 -DocumentPath "path\to\doc.docx" -RecipientName "John Doe" -RecipientEmail "john@example.com" [-SignerName "Ravi Jain"] [-SignerEmail "rjain@technijian.com"] [-SignerTitle "CEO"]

param(
    [Parameter(Mandatory=$true)]
    [string]$DocumentPath,

    [Parameter(Mandatory=$true)]
    [string]$RecipientName,

    [Parameter(Mandatory=$true)]
    [string]$RecipientEmail,

    [string]$SignerName = "Ravi Jain",
    [string]$SignerEmail = "rjain@technijian.com",
    [string]$SignerTitle = "CEO",

    [string]$FolderName = "",
    [string]$EmailSubject = "",
    [string]$EmailMessage = ""
)

# --- Configuration ---
$keysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\foxit-esign.md"
$baseUrl = "https://na1.foxitesign.foxit.com/api"

# --- Read credentials from OneDrive keys file ---
Write-Host "Reading credentials from OneDrive..." -ForegroundColor Cyan
$keysContent = Get-Content $keysFile -Raw
$clientId = [regex]::Match($keysContent, 'Client ID:\*\*\s*(\S+)').Groups[1].Value
$clientSecret = [regex]::Match($keysContent, 'Client Secret:\*\*\s*(\S+)').Groups[1].Value

if (-not $clientId -or -not $clientSecret) {
    Write-Error "Failed to read Foxit eSign credentials from $keysFile"
    exit 1
}
Write-Host "Credentials loaded successfully." -ForegroundColor Green

# --- Validate document ---
if (-not (Test-Path $DocumentPath)) {
    Write-Error "Document not found: $DocumentPath"
    exit 1
}

$fileName = [System.IO.Path]::GetFileName($DocumentPath)
$fileExtension = [System.IO.Path]::GetExtension($DocumentPath).ToLower()

if ($fileExtension -notin @('.pdf', '.docx', '.doc')) {
    Write-Error "Unsupported file type: $fileExtension. Use .pdf, .docx, or .doc"
    exit 1
}

# --- Set defaults ---
if (-not $FolderName) {
    $FolderName = [System.IO.Path]::GetFileNameWithoutExtension($DocumentPath)
}
if (-not $EmailSubject) {
    $EmailSubject = "Technijian - $FolderName - Signature Required"
}
if (-not $EmailMessage) {
    $EmailMessage = "Please review and sign the attached document from Technijian, Inc. If you have any questions, please contact $SignerName at $SignerEmail."
}

# --- Split recipient name ---
$nameParts = $RecipientName.Trim() -split '\s+', 2
$recipientFirst = $nameParts[0]
$recipientLast = if ($nameParts.Length -gt 1) { $nameParts[1] } else { "" }

$signerParts = $SignerName.Trim() -split '\s+', 2
$signerFirst = $signerParts[0]
$signerLast = if ($signerParts.Length -gt 1) { $signerParts[1] } else { "" }

# --- Step 1: Get Access Token ---
Write-Host "`nAuthenticating with Foxit eSign..." -ForegroundColor Cyan
$tokenBody = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "read-write"
}

try {
    $tokenResponse = Invoke-RestMethod -Uri "$baseUrl/oauth2/access_token" -Method POST -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
    $accessToken = $tokenResponse.access_token
    Write-Host "Authentication successful." -ForegroundColor Green
}
catch {
    Write-Error "Authentication failed: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $accessToken"
}

# --- Step 2: Read file as Base64 ---
Write-Host "Reading document: $fileName" -ForegroundColor Cyan
$fileBytes = [System.IO.File]::ReadAllBytes($DocumentPath)
$base64File = [Convert]::ToBase64String($fileBytes)

# --- Step 3: Create and send envelope ---
Write-Host "Creating envelope and sending for signature..." -ForegroundColor Cyan

# Determine content type for the file
$contentType = switch ($fileExtension) {
    '.pdf'  { "application/pdf" }
    '.docx' { "application/vnd.openxmlformats-officedocument.wordprocessingml.document" }
    '.doc'  { "application/msword" }
}

$envelopeData = @{
    folderName          = $FolderName
    inputType           = "base64"
    base64FileString    = @($base64File)
    fileNames           = @($fileName)
    sendNow             = $true
    createEmbeddedSigningSession = $false
    emailSubject        = $EmailSubject
    emailMessage        = $EmailMessage
    signInSequence      = $true
    inPersonEnable      = $false
    parties             = @(
        # Party 1: Client signer (signs first)
        @{
            firstName         = $recipientFirst
            lastName          = $recipientLast
            emailId           = $RecipientEmail
            permission        = "FILL_FIELDS_AND_SIGN"
            sequence          = 1
            workflowSequence  = 1
        },
        # Party 2: Technijian signer (countersigns)
        @{
            firstName         = $signerFirst
            lastName          = $signerLast
            emailId           = $SignerEmail
            permission        = "FILL_FIELDS_AND_SIGN"
            sequence          = 2
            workflowSequence  = 2
        }
    )
    fields              = @(
        # --- Client signature block (right side of signature area) ---
        # Client: Signature
        @{
            type           = "signature"
            x              = 72
            y              = 50
            width          = 200
            height         = 30
            pageNumber     = -1  # last page
            documentNumber = 1
            party          = 1
            required       = $true
        },
        # Client: Name
        @{
            type           = "textfield"
            x              = 72
            y              = 85
            width          = 200
            height         = 20
            pageNumber     = -1
            documentNumber = 1
            party          = 1
            name           = "client_name"
            required       = $true
        },
        # Client: Title
        @{
            type           = "textfield"
            x              = 72
            y              = 110
            width          = 200
            height         = 20
            pageNumber     = -1
            documentNumber = 1
            party          = 1
            name           = "client_title"
            required       = $true
        },
        # Client: Date
        @{
            type           = "datefield"
            x              = 72
            y              = 135
            width          = 120
            height         = 20
            pageNumber     = -1
            documentNumber = 1
            party          = 1
            name           = "client_date"
            required       = $true
        },
        # --- Technijian signature block ---
        # Technijian: Signature
        @{
            type           = "signature"
            x              = 350
            y              = 50
            width          = 200
            height         = 30
            pageNumber     = -1
            documentNumber = 1
            party          = 2
            required       = $true
        },
        # Technijian: Name (prefilled)
        @{
            type           = "textfield"
            x              = 350
            y              = 85
            width          = 200
            height         = 20
            pageNumber     = -1
            documentNumber = 1
            party          = 2
            name           = "tech_name"
            value          = $SignerName
            required       = $true
        },
        # Technijian: Title (prefilled)
        @{
            type           = "textfield"
            x              = 350
            y              = 110
            width          = 200
            height         = 20
            pageNumber     = -1
            documentNumber = 1
            party          = 2
            name           = "tech_title"
            value          = $SignerTitle
            required       = $true
        },
        # Technijian: Date
        @{
            type           = "datefield"
            x              = 350
            y              = 135
            width          = 120
            height         = 20
            pageNumber     = -1
            documentNumber = 1
            party          = 2
            name           = "tech_date"
            required       = $true
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/folders/createfolder" `
        -Method POST `
        -Headers $headers `
        -Body $envelopeData `
        -ContentType "application/json"

    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host " ENVELOPE SENT SUCCESSFULLY" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Folder ID:    $($response.folderId)" -ForegroundColor White
    Write-Host "Folder Name:  $FolderName" -ForegroundColor White
    Write-Host "Document:     $fileName" -ForegroundColor White
    Write-Host "Signer 1:     $RecipientName <$RecipientEmail> (Client)" -ForegroundColor White
    Write-Host "Signer 2:     $SignerName <$SignerEmail> (Technijian)" -ForegroundColor White
    Write-Host "Status:       Sent for signature" -ForegroundColor White
    Write-Host "========================================`n" -ForegroundColor Green

    # Output result as JSON for programmatic use
    $result = @{
        success    = $true
        folderId   = $response.folderId
        folderName = $FolderName
        document   = $fileName
        signers    = @(
            @{ name = $RecipientName; email = $RecipientEmail; role = "Client" },
            @{ name = $SignerName; email = $SignerEmail; role = "Technijian" }
        )
    }
    $result | ConvertTo-Json -Depth 5
}
catch {
    Write-Error "Failed to create envelope: $($_.Exception.Message)"
    if ($_.ErrorDetails) {
        Write-Error "API Response: $($_.ErrorDetails.Message)"
    }
    exit 1
}
