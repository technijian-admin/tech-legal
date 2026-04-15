# Send AmPac / Circle MSP assessment email to Brandon Sellers via Microsoft Graph
# Draft -> send -> saves to Sent Items

$ErrorActionPreference = "Stop"

$recipientEmail = "BSellers@ampac.com"
$recipientName  = "Brandon Sellers"
$senderUpn      = "RJain@technijian.com"
$subject        = "Your Circle MSP Agreement - Initial Assessment and a Few Clarifying Questions"

$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

# --- Credentials ---
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Write-Error "Failed to parse M365 credentials"; exit 1
}

# --- Signature ---
$sig = ""
if (Test-Path $sigPath) { $sig = Get-Content $sigPath -Raw }

# --- HTML body ---
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Brandon,</p>

<p>Thank you for sharing the signed Circle MSP Managed IT Services Proposal. Below is an initial assessment along with a few clarifying questions so we can move quickly and accurately. One note at the outset: this is a business-level read from the MSP side of the fence. Anything that goes in writing to Circle should be reviewed by counsel before it is sent, and I'm glad to help coordinate a short call with an attorney if that would be useful.</p>

<p><strong>What the signed document actually is.</strong> The document on file is a three-page Quote (#10774) for Gold Managed Services with a 36-month term at `$3,177 per month, plus a `$3,600 one-time onboarding fee. That quote incorporates the full Master Service Agreement only by hyperlink (&quot;Master Service Agreement is located at https://circlemsp.com/msa&quot;). The actual termination, cure-period, liquidated-damages, and dispute-resolution terms live in that linked MSA, not in the page AmPac signed.</p>

<p><strong>What that means for AmPac &mdash; three avenues to exit cleanly:</strong></p>

<ol>
<li><strong>Material breach of the services paid for.</strong> The quote sells &quot;Unlimited Remote Support,&quot; &quot;Security Monitoring Services,&quot; and a five-phase onboarding that includes a Comprehensive Audit, Gap Analysis, Compliance Check, and Custom IT Strategy roadmap. If tickets are not being worked and the onboarding deliverables were not completed, that is a direct failure of the consideration AmPac paid for. Under California law (Cal. Civ. Code &sect; 1511; <em>Brown v. Grimes</em> (2011) 192 Cal.App.4th 265, 277&ndash;278), a breach that defeats the core purpose of the contract allows the non-breaching party to terminate without liability, typically after a written notice of breach and a cure period. Thirty days is the common cure window, but the exact period will be specified in the MSA.</li>

<li><strong>Failure-of-consideration rescission</strong> under Cal. Civ. Code &sect; 1689(b)(4). If services AmPac paid for were never delivered &mdash; in particular the cyber security awareness training and the onboarding roadmap &mdash; rescission can unwind the contract and require Circle to <strong>refund fees paid</strong>, not merely release AmPac going forward.</li>

<li><strong>Weak incorporation of the MSA itself.</strong> California requires a document incorporated by reference to be &quot;known or easily available&quot; to the signer at the time of contracting (<em>Shaw v. Regents of Univ. of Cal.</em> (1997) 58 Cal.App.4th 44, 54; <em>Chan v. Drexel Burnham Lambert</em> (1986) 178 Cal.App.3d 632, 641). If Circle never actually provided the MSA text at signing, or if Circle has updated the MSA on their site since AmPac signed, any harsh termination penalties buried in that MSA may not bind AmPac. The note on the quote that &quot;contract prices and fees may be subject to change&quot; compounds the concern; unilateral change-of-terms provisions that are not conspicuously disclosed are vulnerable under <em>Badie v. Bank of America</em> (1998) 67 Cal.App.4th 779.</li>
</ol>

<p><strong>The standard path out for cause</strong> looks like this: (a) a written Notice of Material Breach listing specific, documented failures together with a demand to cure; (b) if Circle does not cure inside the stated window, a Notice of Termination for Cause; (c) transition to a new MSP on the day the termination takes effect, with zero service gap. When executed this way, California law does not treat AmPac as the breaching party, and any early-termination fee in the MSA generally does not apply.</p>

<p><strong>An important precaution before any notice goes out.</strong> Independently secure copies of the environment's critical credentials and data: domain admin, Microsoft 365 global admin, SentinelOne tenant admin, firewall admin, and current backups. Breach-driven terminations can sometimes turn adversarial, and the last thing AmPac needs is an environment-access dispute on top of a contract dispute.</p>

<p><strong>A few clarifying questions so the next step can be precise rather than generic:</strong></p>

<ol>
<li><strong>The MSA itself.</strong> Did Circle provide a copy of the Master Service Agreement at signing (as an email attachment, PDF, or printed copy), or only the hyperlink on the quote? If AmPac has any version they were given, could you forward it so I can pull the exact termination and cure-period language?</li>
<li><strong>Specific service failures.</strong> Could you share three to five example tickets that were not worked &mdash; open date, subject, how long the ticket has sat, and any response from Circle? Concrete examples carry far more weight in a breach notice than a general statement that tickets are not being addressed.</li>
<li><strong>The cyber training promise.</strong> Was security awareness training promised in writing (email, proposal attachment, statement of work), or orally during the sales cycle? Is there any record of AmPac asking for it and not receiving a response?</li>
<li><strong>Authorized signatory.</strong> Who is the authorized signer at AmPac for the Notice of Material Breach? Please confirm the name and title as they should appear on the letter.</li>
</ol>

<p>Once I have those four items, I can put together a clean Notice of Material Breach for AmPac's counsel to review and, on their sign-off, for AmPac to send. In parallel, Technijian can begin discovery and tool-deployment planning so the transition is immediate the day your termination takes effect.</p>

<p>Happy to hold a fifteen-minute call this week to walk through this and line up the next steps.</p>

</div>
$sig
</body>
</html>
"@

# --- Preflight check for unresolved `$` references ---
if ($htmlBody -match '\`$[a-zA-Z_]') {
    Write-Warning "Body contains an unescaped PowerShell variable reference; check your `$ escaping."
}

# --- Connect ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Create draft ---
Write-Host "Creating draft message..." -ForegroundColor Cyan
$draftParams = @{
    Subject = $subject
    Body = @{
        ContentType = "HTML"
        Content     = $htmlBody
    }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = $recipientEmail; Name = $recipientName } }
    )
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

# --- Send ---
Write-Host "Sending..." -ForegroundColor Cyan
Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
Write-Host "`nSENT to $recipientEmail." -ForegroundColor Green
Write-Host "Subject: $subject" -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
