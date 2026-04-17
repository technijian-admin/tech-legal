# Patch the BST response draft in Outlook: replace only Section 1 in place,
# preserving all other edits (Cc list, bullet flattening, bold removal).

$ErrorActionPreference = "Stop"
$senderUpn     = "RJain@technijian.com"
$messageId     = "AAMkAGNlYjM0OTA4LThjMjYtNGQ3My1iNDg1LTQ2MTI5NTg0NzFlOQBGAAAAAAC88IffM67WS4tSyVwwqYmJBwBhk-ls8ubYRazD3tGgncxCAAAAAAEQAACgx7VhNWW1QYCgfGa-8kbOAAXP9qoXAAA="

# --- Graph auth ---
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$secure = ConvertTo-SecureString $sec -AsPlainText -Force
$cred   = New-Object System.Management.Automation.PSCredential($cid, $secure)
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Fetch current body ---
$getUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId" + "?`$select=body"
$full = Invoke-MgGraphRequest -Method GET -Uri $getUri
$html = $full.body.content

# --- Locate §1 boundaries in current HTML ---
# Anchor: the <p ...> that wraps "1. April monthly invoices and late fees."
# End:    the <p ...> that wraps "2. Cancellation reconciliation"
$i1Heading = $html.IndexOf('1. April monthly invoices and late fees')
$i2Heading = $html.IndexOf('2. Cancellation reconciliation')
if ($i1Heading -lt 0 -or $i2Heading -lt 0) {
    Write-Error "Could not locate section anchors in draft HTML."
    Disconnect-MgGraph | Out-Null
    exit 1
}
$leftAnchor  = $html.LastIndexOf('<p class="elementToProof"', $i1Heading)
$rightAnchor = $html.LastIndexOf('<p class="elementToProof"', $i2Heading)
if ($leftAnchor -lt 0 -or $rightAnchor -lt 0) {
    Write-Error "Could not locate wrapping <p> anchors."
    Disconnect-MgGraph | Out-Null
    exit 1
}

$oldSection1 = $html.Substring($leftAnchor, $rightAnchor - $leftAnchor)
Write-Host ("Old §1 block: {0} chars" -f $oldSection1.Length) -ForegroundColor Yellow

# --- Build replacement §1 HTML in the user's established style ---
# Style constants matching the existing draft
$font = 'Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif'
$pStyle  = 'direction:ltr; margin-top:1em; margin-bottom:1em'
$spStyle = "font-family:$font; font-size:12pt; color:rgb(0,0,0)"
$liStyle = "font-family:$font; font-size:12pt; color:rgb(0,0,0); direction:ltr"

function NewParagraph($text) {
    "<p class=`"elementToProof`" style=`"$pStyle`"><span style=`"$spStyle`">$text</span></p>"
}
function NewListItem($text, $withSeparator) {
    if ($withSeparator) {
        "<li style=`"$liStyle`"><div role=`"presentation`">$text</div><div role=`"presentation`"><br></div></li>"
    } else {
        "<li style=`"$liStyle`">$text</li>"
    }
}

# Invoice list items (5 entries, last one no trailing separator)
$invoiceItems = @(
    'Invoice #27890, dated 3/1/2026, Recurring, due 3/31/2026 &mdash; overdue, &#36;552.00.',
    'Invoice #27949, dated 3/1/2026, March 2026 Monthly, due 3/31/2026 &mdash; overdue, &#36;5,645.35.',
    'Invoice #28064, dated 3/30/2026, Service Cancellation, due 4/30/2026, &#36;126,442.50.',
    'Invoice #28112, dated 4/1/2026, Recurring, due 5/1/2026, &#36;552.00.',
    'Invoice #28143, dated 4/1/2026, April 2026 Monthly, due 5/1/2026, &#36;5,694.60.'
)
$invoiceListHtml = "<ul style=`"direction:ltr`">"
for ($i = 0; $i -lt $invoiceItems.Count; $i++) {
    $sep = ($i -lt $invoiceItems.Count - 1)
    $invoiceListHtml += (NewListItem $invoiceItems[$i] $sep)
}
$invoiceListHtml += "</ul>"

# Clarification bullets (4 entries)
$clarItems = @(
    'Late fees have already been assessed on invoices #27890 and #27949 (both dated 3/1/2026, both due 3/31/2026). Those late fees will not be waived. Technijian has previously waived late fees for Boston Group as a business courtesy on two prior occasions; those were discretionary, non-precedential accommodations, and no further waivers will be granted.',
    'All five outstanding invoices &mdash; totaling &#36;138,886.45 in principal plus accrued late fees on the two overdue items &mdash; must be paid in full on or before April&nbsp;30,&nbsp;2026. That includes the March monthly and recurring (already overdue), the cancellation invoice (#28064), and the April monthly and recurring invoices.',
    'Any invoice that remains unpaid after its due date will continue to accrue the contractual 10% late fee per the Agreement until paid.',
    'Your April&nbsp;16 statement that the April monthly charges &ldquo;will be paid as soon as possible&rdquo; is noted, but &ldquo;as soon as I can&rdquo; is not a commitment we can rely on to stop the late-fee clock. A firm remittance date or a written payment arrangement from AP &mdash; covering all five open invoices &mdash; would avoid further late-fee accrual.'
)
$clarListHtml = "<ul style=`"direction:ltr`">"
for ($i = 0; $i -lt $clarItems.Count; $i++) {
    $sep = ($i -lt $clarItems.Count - 1)
    $clarListHtml += (NewListItem $clarItems[$i] $sep)
}
$clarListHtml += "</ul>"

# Opening paragraph + intro to invoice list
$intro = '1. Outstanding invoices and late fees &mdash; full accounting.&nbsp;I want the record to be precise on what is outstanding and when it is due. Boston Group currently has five open invoices on the Technijian account, all in &ldquo;Pending Payment&rdquo; status, as follows:'

# Paragraph linking invoice list to clarification bullets
$transition = 'Payment terms under the Agreement are Net-30, with a 10% late fee assessed on any balance unpaid after the 10th of the month following the invoice date (Other Terms, Paragraph&nbsp;3). For clarity, please understand:'

$newSection1 = (NewParagraph $intro) + $invoiceListHtml + (NewParagraph $transition) + $clarListHtml

Write-Host ("New §1 block: {0} chars" -f $newSection1.Length) -ForegroundColor Cyan

# --- Replace in HTML ---
$newHtml = $html.Substring(0, $leftAnchor) + $newSection1 + $html.Substring($rightAnchor)

# --- Save a preview before we PATCH ---
$previewPath = "C:\vscode\tech-legal\tech-legal\terminated-clients\BST\_working\_patched_draft_preview.html"
Set-Content -Path $previewPath -Value $newHtml -Encoding UTF8
Write-Host "Patched body preview written: $previewPath" -ForegroundColor Green

# --- PATCH via Graph ---
Write-Host "Patching message body via Graph..." -ForegroundColor Cyan
$patchBody = @{
    body = @{
        contentType = "HTML"
        content     = $newHtml
    }
} | ConvertTo-Json -Depth 5
$headers = @{ "Content-Type" = "application/json" }
Invoke-MgGraphRequest -Method PATCH `
    -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId" `
    -Body $patchBody `
    -Headers $headers | Out-Null
Write-Host "Draft body updated." -ForegroundColor Green

Disconnect-MgGraph | Out-Null
