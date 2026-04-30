# Creates an Outlook DRAFT (does NOT send) - Reply to Frank Dunn re Sunrun
# After re-reading both contracts, this concedes the 2012 PPA point but flags
# the 2017 Limited Warranty (active, separate from "production guarantee") and
# the absence of any arbitration clause in the 2017 Costco contract.

$ErrorActionPreference = "Stop"

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

$sig = Get-Content "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html" -Raw

$htmlBody = @'
<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:#000000; max-width:780px;">

<p>Frank,</p>

<p>Thank you for the analysis &mdash; it pushed me to re-read both contracts cover-to-cover. You are right on the 2012 PPA, and I want to set that piece aside. But there are a few items in the 2017 Costco contract that I want to make sure we have considered before responding to Gabby. Apologies for the length; I am trying to give you everything in one place so you have the contract citations on hand.</p>

<hr style="border:1px solid #e0e0e0; margin:20px 0;" />

<h3 style="color:#1a1a2e; font-size:13pt;">1. 2012 PPA &mdash; Conceded</h3>

<p>You are correct that the Section 8 guarantee is a cumulative inception-to-date measurement, not a per-period refund. Section 8(a) defines &ldquo;Actual Output&rdquo; as energy created &ldquo;to date,&rdquo; Exhibit A&rsquo;s column header reads &ldquo;Guaranteed kWh Output <strong>to Date</strong>,&rdquo; and Section 8(d) explicitly authorizes Sunrun to use overproduction to offset future underproduction. If Sunrun&rsquo;s 105.4% lifetime figure for System #1622893336 is accurate, no Section 8 credit is owed at the next anniversary, and we should not pursue this further.</p>

<p>The only remaining 2012 PPA item I would want is the underlying production data from Sunrun&rsquo;s dedicated meter on that system &mdash; just to confirm the 105.4% figure represents that system specifically and not a combined SDG&amp;E meter reading. If the data backs the percentage, this issue is closed.</p>

<hr style="border:1px solid #e0e0e0; margin:20px 0;" />

<h3 style="color:#1a1a2e; font-size:13pt;">2. 2017 Costco &mdash; Limited Warranty Was Not Addressed by Sunrun&rsquo;s Response</h3>

<p>This is the point I would like your read on. The 2017 Costco Home Improvement Sales Contract contains a 10-year Limited Warranty on pages 9&ndash;10 that is separate from any production guarantee. Section 2 of that warranty reads:</p>

<blockquote style="border-left:4px solid #006DB6; margin:10px 0; padding:8px 16px; background-color:#f0f7ff; font-style:italic;">
&ldquo;Sunrun provides a limited warranty of ten (10) years (the &lsquo;Limited Warranty Period&rsquo;), counted from the date the permit is signed by the building inspector. During the Limited Warranty Period, Sunrun warrants (i) all of its labor, and (ii) the rated electrical output of the System will not be less than 85% of the DC nameplate rating (measured in kW) measured upon completion of the installation as a result of <strong>defects in parts Sunrun supplied or labor Sunrun performed</strong> to install the System.&rdquo;
</blockquote>

<p>Section 4 then provides the remedy: &ldquo;Sunrun will repair or replace the defect within a <strong>reasonable time</strong> after you notify Sunrun.&rdquo;</p>

<p>PTO on this system was March 14, 2018, which puts the warranty in force through March 14, 2028 &mdash; it is fully active today.</p>

<p><strong>The factual fit is straightforward:</strong> On April 22, 2026, Sunrun&rsquo;s own technician identified a defective uplink circuit and replaced it &mdash; that is a Sunrun-supplied part. The system was non-operational from November 7, 2025 through April 16, 2026 (with the uplink not fully restored until April 22), output was at 0% of the DC nameplate rating during that period (well below the 85% threshold), and the cause was the defective component the technician replaced. By any reading, that triggers the Limited Warranty.</p>

<p>Sunrun&rsquo;s response framed this as &ldquo;the 2017 system has no production guarantees,&rdquo; which is correct as to the absence of a minimum kWh output guarantee but does not address the Limited Warranty obligation, which is a separate remedy. I want to make sure we are not conflating the two.</p>

<hr style="border:1px solid #e0e0e0; margin:20px 0;" />

<h3 style="color:#1a1a2e; font-size:13pt;">3. The $0.11/kWh Rate Has No Basis in the 2017 Costco Contract</h3>

<p>I read the 2017 Costco contract front to back. It contains no per-kWh compensation rate for warranty claims, lost production, or any similar damages. The $0.11 figure Sunrun used appears to have been borrowed from the 2012 PPA&rsquo;s Exhibit A (Year 2 refund rate is $0.114/kWh, rounding to $0.11) &mdash; but the 2012 PPA refund rate has no application to a 2017 contract claim.</p>

<p>For a Limited Warranty breach, the measure of damages should be the actual cost of replacement electricity. My SDG&amp;E rate schedule (EVTOU5-Residential) yields effective rates from approximately $0.47/kWh (winter on-peak) to $0.70/kWh (summer on-peak), with the cumulative NEM deficit on the November 2025 True-Up bill at $2,098.55 and the bill itself at $2,712.00 due. At a conservative blended $0.45/kWh, the 6,149 kWh Sunrun concedes equals $2,767 &mdash; already more than their $2,000 offer.</p>

<hr style="border:1px solid #e0e0e0; margin:20px 0;" />

<h3 style="color:#1a1a2e; font-size:13pt;">4. The 2017 Costco Contract Does Not Contain an Arbitration Clause</h3>

<p>I want to flag this because it changes the calculus on the cost-of-pursuit point you raised. The 2012 PPA has a JAMS arbitration clause (Section 16), and I agree arbitration is uneconomical for a dispute of this size. But the 2017 Costco Home Improvement Sales Contract contains no arbitration clause &mdash; I checked all 12 pages.</p>

<p>If the 2017 system is the one where the breach occurred (which appears to be the case based on the technician&rsquo;s diagnosis), then small claims court (CCP &sect; 116.220, $12,500 cap) would be available as a parallel track. Filing fee is roughly $75. No attorneys present at the hearing, simple process. That meaningfully changes the cost-benefit on whether to push past $2,000.</p>

<hr style="border:1px solid #e0e0e0; margin:20px 0;" />

<h3 style="color:#1a1a2e; font-size:13pt;">5. Where I Land</h3>

<p>If your read aligns with mine after looking at the warranty language and the missing arbitration clause, my preference would be to counter Gabby in the $3,500&ndash;$4,000 range, justified entirely on the 2017 system at retail-rate damages under the Limited Warranty &mdash; without engaging the 2012 PPA at all. That keeps the argument narrow and well-supported.</p>

<p>If you still believe $2,000 is the practical ceiling after considering the warranty and the small claims option, I will defer to your judgment and accept it. I just want to make sure we are not leaving a clean argument on the table because Sunrun&rsquo;s response framed the issue as &ldquo;production guarantee&rdquo; rather than &ldquo;Limited Warranty.&rdquo;</p>

<p>Happy to jump on a quick call if it is easier than email. Gabby is out of office May 14&ndash;18, so a counter before that window would be ideal.</p>

<br>
</div>
'@ + $sig

$draftParams = @{
    Subject    = "RE: Complaint received for Ravi Jain"
    Body       = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = "fdunn@callahan-law.com"; Name = "Franklin T. Dunn" } }
    )
    CcRecipients = @(
        @{ EmailAddress = @{ Address = "ES@callahan-law.com"; Name = "Edward Susolik" } }
    )
}

$draft = New-MgUserMessage -UserId "RJain@technijian.com" -BodyParameter $draftParams
Write-Host "Draft created successfully." -ForegroundColor Green
Write-Host "Draft ID: $($draft.Id)" -ForegroundColor Cyan
Write-Host "Subject:  $($draft.Subject)" -ForegroundColor Cyan
Write-Host "To:       fdunn@callahan-law.com (Franklin T. Dunn)" -ForegroundColor Cyan
Write-Host "CC:       ES@callahan-law.com (Edward Susolik)" -ForegroundColor Cyan
