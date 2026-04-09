# Send BWH Executive Summary to Dave + MSA via DocuSign branded email

# ============ PART 1: EMAIL EXECUTIVE SUMMARY ============
Write-Host "=== Sending Executive Summary Email ===" -ForegroundColor Cyan

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID:\*\*\s*(\S+)').Groups[1].Value
$m365Secret = [regex]::Match($m365Keys, 'Client Secret:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

$docPath = "C:\vscode\tech-legal\tech-legal\clients\BWH\BWH-Executive-Summary.docx"
$docBytes = [System.IO.File]::ReadAllBytes($docPath)
$docBase64 = [Convert]::ToBase64String($docBytes)

$sigHtml = Get-Content "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html" -Raw

$bodyHtml = @"
<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">

<p>Hi Dave,</p>

<p>Thank you for the opportunity to continue partnering with Brandywine Homes on your managed IT services. As discussed, I've prepared an Executive Summary that outlines the transition from the current Terms &amp; Conditions to a formal Master Service Agreement (MSA).</p>

<p>The attached summary highlights key improvements effective May 1, 2026:</p>

<ul>
<li><strong>Desktop optimization</strong> &#8212; Updated count from 41 to 32 endpoints</li>
<li><strong>Service consolidation</strong> &#8212; Streamlined services into a single monthly invoice</li>
<li><strong>Backup storage optimization</strong> &#8212; Right-sized from 24 TB to 13 TB with deduplication</li>
<li><strong>15% Virtual Staff rate reduction</strong> &#8212; Applied across all support roles</li>
</ul>

<p>These changes bring your monthly investment from <strong>&#36;10,275.75 to &#36;8,356.89</strong>, a savings of <strong>&#36;1,918.86/month (18.7%)</strong>.</p>

<p>The summary also includes an Unpaid Hours Recovery Plan to address the accumulated balance over the 12-month billing cycle.</p>

<p>I'll be sending the MSA for signature via DocuSign shortly. Please review the Executive Summary and let me know if you have any questions.</p>

</div>
$sigHtml
</body></html>
"@

$params = @{
    Message = @{
        Subject = "Brandywine Homes - MSA Executive Summary & Cost Optimization"
        Body = @{ ContentType = "HTML"; Content = $bodyHtml }
        ToRecipients = @(@{ EmailAddress = @{ Address = "dave@brandywine-homes.com"; Name = "Dave Barisic" } })
        Attachments = @(@{
            "@odata.type" = "#microsoft.graph.fileAttachment"
            Name = "Brandywine-Homes-Executive-Summary-May2026.docx"
            ContentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            ContentBytes = $docBase64
        })
    }
    SaveToSentItems = $true
}

Send-MgUserMail -UserId "RJain@technijian.com" -BodyParameter $params
Write-Host "Executive Summary sent to Dave Barisic <dave@brandywine-homes.com>" -ForegroundColor Green

# ============ PART 2: DOCUSIGN MSA ============
Write-Host "`n=== Sending MSA via DocuSign (Branded Email) ===" -ForegroundColor Cyan

& "C:\vscode\tech-legal\tech-legal\scripts\send-docusign.ps1" `
    -DocumentPath "C:\vscode\tech-legal\tech-legal\clients\BWH\MSA-BWH.docx" `
    -RecipientName "Dave Barisic" `
    -RecipientEmail "dave@brandywine-homes.com" `
    -ClientCompanyName "Brandywine Homes"
