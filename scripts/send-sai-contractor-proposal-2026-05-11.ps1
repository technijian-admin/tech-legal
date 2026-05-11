# Draft email to Sai Revanth -- response to his contractor-via-brother proposal.
# Lays out the terms ($5K/mo flat), what brother's company has to be/do, the
# visa-question gate, and the Services Agreement path. Coming from Sai's ask
# (not Ravi's idea), so tone is open / conditional / not directive.
#
# Usage:
#   .\send-sai-contractor-proposal-2026-05-11.ps1          # draft only (DEFAULT)
#   .\send-sai-contractor-proposal-2026-05-11.ps1 -Send    # send immediately

param([switch]$Send)

$ErrorActionPreference = "Stop"

$senderUpn = "RJain@technijian.com"
$subject   = "Your contractor proposal -- terms and what is needed"

$to = @(
    @{ Address = "srevanth@Technijian.com"; Name = "Sai Revanth" }
)

# Aptos 12pt rgb(0,0,0) one-div-per-line pattern -- matches Ravi's Outlook native format.
$div = 'style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"'
$blank = "<div $div><br></div>"

$bodyText = @"
<div class="elementToProof" $div>Sai,</div>
$blank
<div $div>Thank you for raising the idea of moving to your brother's company so you can work on your visa. I have thought it through and I am willing to make it work if we can structure it the right way. Here is where I land.</div>
$blank
<div $div><b>The arrangement.</b> I would end your Technijian / Sequoia employment and engage your brother's company on a contracted services basis. Technijian would pay brother's company a flat <b>`$5,000 per month -- `$60,000 per year</b> -- as the total cost for your services. Brother's company would be responsible for everything else: your W-2 wages, employer-side payroll taxes (FICA, FUTA, CA SUI/ETT/SDI), workers comp coverage, and any benefits. Nothing else flows from Technijian.</div>
$blank
<div $div><b>What brother's company needs to be.</b> For this to hold up under IRS, EDD, or DOL review, brother's company has to look like a real business, not a paper company set up to receive a check. Specifically:</div>
$blank
<div $div>1. Legitimate legal entity -- LLC or corporation in good standing, EIN, separate business bank account.</div>
<div $div>2. Registered with the California EDD as an employer; filing federal 941s and CA DE-9 / DE-9C quarterly on time.</div>
<div $div>3. Workers comp coverage on you (CA requires it for every W-2 employee), plus general liability and professional liability / E&amp;O insurance. We will need certificates of insurance naming Technijian as additional insured.</div>
<div $div>4. Brother's company carries the I-9 obligation as your employer of record, and any visa-sponsorship obligations as your sponsoring employer (whichever visa path applies).</div>
<div $div>5. Ideally has or is willing to take on at least one other client, so it does not read as a single-client pass-through. Not strictly required, but it strengthens the structure.</div>
$blank
<div $div><b>The visa question -- this is the gating issue.</b> Before we go further, I need to know exactly which visa you are on today and which visa your brother's company is sponsoring for you. Some visas allow this kind of arrangement cleanly; others do not, and trying to make them work creates real risk for you and for Technijian. The short version:</div>
$blank
<div $div>- If you are on an EAD or are a green-card holder: no concern, you can work for any employer.</div>
<div $div>- If you are on H-1B, F-1 OPT, STEM OPT, or pursuing a PERM through your brother's company: USCIS looks very carefully at arrangements where one entity is the employer of record on paper but the day-to-day work is for a different end-client. We would need an immigration attorney to confirm the path before we proceed. I am not willing to put your status at risk, and I am not willing to put Technijian at risk of an immigration finding.</div>
$blank
<div $div>Please confirm in your reply: (a) the visa you hold today, and (b) the visa your brother's company is sponsoring. I am happy to introduce you to immigration counsel if that helps.</div>
$blank
<div $div><b>Services Agreement.</b> Once the visa picture is clear and the entity is set up properly, we sign a Services Agreement between Technijian and brother's company. Standard professional services contract: scope, the `$5,000 monthly fee, indemnities, termination on 30 days' notice, insurance minimums, IP assignment back to Technijian for any work product, confidentiality. I will draft a first version. Either my counsel can handle both sides or your brother is welcome to have his counsel review -- whichever your brother prefers.</div>
$blank
<div $div><b>How the day-to-day changes.</b> Once this is in place you would no longer be a Technijian employee. Direction flows through the Services Agreement scope, not employee-style supervision. Practically your work will look similar, but the structure has to actually be a vendor relationship for the arrangement to be legitimate. That is part of what makes it work.</div>
$blank
<div $div><b>Effective date.</b> Whenever the paperwork is in place -- entity verification, COIs, Services Agreement, visa confirmation. I am not putting a clock on this; better to get it right.</div>
$blank
<div $div>If your brother is on board with what is above, ask him to send me his entity details and proof of insurance, and I will move on the Services Agreement. And please confirm the visa question first -- that determines whether any of the rest can move forward.</div>
"@

$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"
$signature = Get-Content $sigPath -Raw
$htmlBody = $bodyText + "`n" + $signature

Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome

Write-Host "Creating draft..." -ForegroundColor Cyan
$toRecipients = @()
foreach ($r in $to) {
    $toRecipients += @{ EmailAddress = @{ Address = $r.Address; Name = $r.Name } }
}

$draftParams = @{
    Subject      = $subject
    Body         = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = $toRecipients
}

$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created: $($draft.Id)" -ForegroundColor Green
Write-Host "  Subject: $subject" -ForegroundColor Gray
Write-Host "  To:      $($to | ForEach-Object { $_.Address } | Join-String -Separator ', ')" -ForegroundColor Gray

if ($Send) {
    Write-Host "Sending..." -ForegroundColor Yellow
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "SENT." -ForegroundColor Green
} else {
    Write-Host "Draft saved. Review in Outlook Drafts; re-run with -Send to send." -ForegroundColor Cyan
}
