# DocuSign - Send SOW-AFFG-002 for Parallel Signature
# Uses JWT Grant authentication with RSA key

$DocumentPath = "C:\vscode\tech-legal\tech-legal\clients\AFFG\SOW-AFFG-002-WirelessAP.docx"
$ClientId = "97d42eae-c23f-4a5b-a212-c0ef2384d231"
$UserId = "9a6b1aeb-88c5-4405-a0d2-b75c52a8cb63"
$AccountId = "fe3baf59-68ed-48a9-9ed7-5185f111c2a4"
$BaseUrl = "https://na1.docusign.net/restapi"
$OAuthUrl = "https://account.docusign.com/oauth/token"

# RSA Private Key (from keys file)
$rsaKey = @"
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAnlgyBeI3B2vQty5E1mtXEQhnOk0gew0QYJk9PfuZAgkuTERb
KmtwU9DbO40oQKYLWawVWNDuin3i2L/AH8N/MUOCjDutEQ+CETEq47B4eRpB63xA
1pakv01jaVmVUp0cPY+9F2ndyBJPfvCCIAK308xLwnzZFIX35WlLNDd0uh1UyjDs
n3IY4aE5OszzxZyuNSfFXczVs4HAtPeehoTXKNss6DHcjxS2BIXp1nlzfND41I/Z
x870dUTY5mee7VQw5mUa60KD1m9JO9OW6Yisza38OD/bXiKVC2yS8w2bwbPweYqQ
r3aq5CM+8V9THYuahzhoqBVV6ds4yCzxV5obDQIDAQABAoIBABxrE78+lEW+sdzO
bwhUh3HFIlGyWev7sj7EAdvH9fQJlceWVQ5N7gD88PvFH75KjqrvWX1xMf6lDTt9
XovU2FUNGrb0VuFC+UMAogPvPg/uCHqs+C4LJ1I2H2te6o/DJrhdvcAf/e/UaXQM
0i3QjxFyDv6+zW8DhDQmK5sZgNeN9zUcXgiWb5H3LQzbSTLr3KhgvNpuBKOxGCpK
acNIVwO9bPhdnfY4ojKt9h2+/O+7/kES22Kqz7GlrssGqOT2WHJhnZGnx4EFymGu
Z0al6l47xP6oq5ZUchPGBlGybENkyj225Rger7TuSBQ9/cNh9TN96hyPJoN6d8W2
obfbEnkCgYEA5QRpm0D9fULs3Oy+jYlw0qFaKuXbgvKfxyI+4oxhQH5wXbv2Tne1
lv5vREWY+MQktcx+Zoy7/A+naxJ2LvLKQXLiaT6Nfa87dCO3o/7jRhOT5TQ7R5XZ
JNwhlN2AU9v6aczPbyVt9AZbsPhtR/Kkrkp/3mQ8BD9m6cExpgVGpPMCgYEAsQAp
XbXwy6sYJxxLS/A7XRLshsR+NOXuu3gcuLgO58KnYzkPq28deAOakaKzPKHBgTZy
bMx1xouLDL2UohcGI6vhapsim3y19OHw1VY58nR+ku+yV/5v/zg24S+yf/fPbftz
uWSwqClZDa2X77a5/LQZclAvF+NIfYNs1TbMP/8CgYEAgq3l5OVMv/E0X0vn37OR
YV8YqGnIvAveCC8OWw9nXvnG/HWIsnW0dJhyvS5Jf4nMuMAbUED183qrOXmrXlbD
+lynvQ4ohpM7BaZr33ROE2qQdbU8LjjfUx0ZPGy4ESHw3fY0V2OwPhJyt6TKFsfq
GFoCZNAlPvc+rhvDTMyt5ukCgYAYIPOCqNjIiuxh+INzOK5/A6Nmw8aIo4el2rvf
moe9pFV5O0AdmKolwCgEDm/spghg+vEiT8UGaeNsuzNV3Vmi5z11cOyI0blkRqC0
FGsV2DehBDgFstPFsP4aOIxW0YtfbNXbwhQq+GgBa1a5AOndvxdw8+lXkk5BffcK
Icw6NQKBgQDgbeMp7iMqoHFIFR0zPSPHIvDi5fELtBBGCU/5SrrL6jz6G2a2q8Tm
ljWRdlgCvBfcex51yotpZ+fRbYzokZR/xOaYXXiLpi1dXmdfOxiLruy70FQM8S0v
xjYZZnp/OWKJZ/cczNHQ2B7iUEsGBpBoZy8joN8ZatVjLcuy+DYDEw==
-----END RSA PRIVATE KEY-----
"@

# --- Helper: Create JWT ---
function New-DocuSignJWT {
    param($ClientId, $UserId, $OAuthHost, $RSAKey)

    # JWT Header
    $header = @{ alg = "RS256"; typ = "JWT" } | ConvertTo-Json -Compress
    $headerB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($header)).TrimEnd('=').Replace('+','-').Replace('/','_')

    # JWT Payload
    $now = [int]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
    $payload = @{
        iss   = $ClientId
        sub   = $UserId
        aud   = "account.docusign.com"
        iat   = $now
        exp   = $now + 3600
        scope = "signature impersonation"
    } | ConvertTo-Json -Compress
    $payloadB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payload)).TrimEnd('=').Replace('+','-').Replace('/','_')

    # Sign with RSA - extract base64 from PEM and import
    $dataToSign = "$headerB64.$payloadB64"
    $pemLines = $RSAKey -split "`n" | Where-Object { $_ -notmatch "-----" -and $_.Trim() -ne "" }
    $keyBase64 = ($pemLines -join "").Trim()
    $keyBytes = [Convert]::FromBase64String($keyBase64)

    $rsa = [System.Security.Cryptography.RSA]::Create()
    $rsa.ImportRSAPrivateKey($keyBytes, [ref]$null)
    $signatureBytes = $rsa.SignData(
        [System.Text.Encoding]::UTF8.GetBytes($dataToSign),
        [System.Security.Cryptography.HashAlgorithmName]::SHA256,
        [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
    )
    $signatureB64 = [Convert]::ToBase64String($signatureBytes).TrimEnd('=').Replace('+','-').Replace('/','_')

    return "$dataToSign.$signatureB64"
}

# --- Step 1: Get Access Token via JWT Grant ---
Write-Host "Authenticating with DocuSign (JWT Grant)..." -ForegroundColor Cyan

$jwt = New-DocuSignJWT -ClientId $ClientId -UserId $UserId -OAuthHost "account.docusign.com" -RSAKey $rsaKey

$tokenBody = @{
    grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
    assertion  = $jwt
}

try {
    $tokenResponse = Invoke-RestMethod -Uri $OAuthUrl -Method POST -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
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
    "Content-Type"  = "application/json"
}

# --- Step 2: Read document as Base64 ---
Write-Host "Reading document..." -ForegroundColor Cyan
$fileName = [System.IO.Path]::GetFileName($DocumentPath)
$fileBytes = [System.IO.File]::ReadAllBytes($DocumentPath)
$base64File = [Convert]::ToBase64String($fileBytes)

# --- Step 3: Create Envelope with parallel signing ---
Write-Host "Creating DocuSign envelope (parallel signing)..." -ForegroundColor Cyan

$envelope = @{
    emailSubject = "Technijian - SOW-AFFG-002 Wireless Access Point - Signature Required"
    emailBlurb   = "Please review and sign the attached Statement of Work for Wireless Access Point Deployment from Technijian, Inc."
    status       = "sent"
    documents    = @(
        @{
            documentBase64 = $base64File
            name           = $fileName
            fileExtension  = "docx"
            documentId     = "1"
        }
    )
    recipients   = @{
        signers = @(
            # Signer 1: Iris Liu (Client) - routingOrder 1 for parallel
            @{
                email        = "iris.liu@americanfundstars.com"
                name         = "Iris Liu"
                recipientId  = "1"
                routingOrder = "1"
                tabs         = @{
                    signHereTabs = @(
                        @{
                            anchorString  = "By: ___"
                            anchorUnits   = "pixels"
                            anchorXOffset = "40"
                            anchorYOffset = "-5"
                            documentId    = "1"
                            pageNumber    = "0"
                            recipientId   = "1"
                            anchorCaseSensitive = $false
                        }
                    )
                    dateSignedTabs = @(
                        @{
                            anchorString  = "Date: ___"
                            anchorUnits   = "pixels"
                            anchorXOffset = "50"
                            anchorYOffset = "0"
                            documentId    = "1"
                            pageNumber    = "0"
                            recipientId   = "1"
                            anchorCaseSensitive = $false
                        }
                    )
                    textTabs = @(
                        @{
                            anchorString  = "Name: ___"
                            anchorUnits   = "pixels"
                            anchorXOffset = "55"
                            anchorYOffset = "0"
                            documentId    = "1"
                            pageNumber    = "0"
                            recipientId   = "1"
                            tabLabel      = "client_name"
                            required      = "true"
                            anchorCaseSensitive = $false
                        },
                        @{
                            anchorString  = "Title: ___"
                            anchorUnits   = "pixels"
                            anchorXOffset = "50"
                            anchorYOffset = "0"
                            documentId    = "1"
                            pageNumber    = "0"
                            recipientId   = "1"
                            tabLabel      = "client_title"
                            required      = "true"
                            anchorCaseSensitive = $false
                        }
                    )
                }
            },
            # Signer 2: Ravi Jain (Technijian) - routingOrder 1 for parallel
            @{
                email        = "rjain@technijian.com"
                name         = "Ravi Jain"
                recipientId  = "2"
                routingOrder = "1"
                tabs         = @{
                    signHereTabs = @(
                        @{
                            anchorString  = "TECHNIJIAN, INC."
                            anchorUnits   = "pixels"
                            anchorXOffset = "0"
                            anchorYOffset = "40"
                            documentId    = "1"
                            recipientId   = "2"
                            anchorCaseSensitive = $false
                        }
                    )
                }
            }
        )
    }
} | ConvertTo-Json -Depth 15

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/v2.1/accounts/$AccountId/envelopes" `
        -Method POST `
        -Headers $headers `
        -Body $envelope `
        -TimeoutSec 60

    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host " DOCUSIGN ENVELOPE SENT SUCCESSFULLY" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Envelope ID:  $($response.envelopeId)" -ForegroundColor White
    Write-Host "Status:       $($response.status)" -ForegroundColor White
    Write-Host "Document:     $fileName" -ForegroundColor White
    Write-Host "Signer 1:     Iris Liu <iris.liu@americanfundstars.com> (parallel)" -ForegroundColor White
    Write-Host "Signer 2:     Ravi Jain <rjain@technijian.com> (parallel)" -ForegroundColor White
    Write-Host "========================================`n" -ForegroundColor Green
}
catch {
    Write-Error "Failed to create envelope: $($_.Exception.Message)"
    if ($_.ErrorDetails) {
        Write-Error "API Response: $($_.ErrorDetails.Message)"
    }
    exit 1
}
