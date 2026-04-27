# DRAFT email to Frank Dunn explaining the proper Section 5 cancellation-fee
# textual reading and applying it to BST (settled) and VTD (active arbitration).
# Goal: ensure VTD anchor numbers are right before any settlement movement.
# Does NOT send. Ravi reviews in Outlook before clicking Send.

$ErrorActionPreference = "Stop"

$senderUpn = "RJain@technijian.com"
$sigPath   = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

$toEmail   = "fdunn@callahan-law.com"
$toName    = "Franklin T. Dunn, Esq."
$ccEmail   = "es@callahan-law.com"
$ccName    = "Edward Susolik, Esq."

$subject   = "Section 5 Cancellation Fee - Proper Textual Calculation (BST Settled / VTD Still Open)"

# --- Credentials ---
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

# --- Signature ---
$sig = ""
if (Test-Path $sigPath) { $sig = [System.IO.File]::ReadAllText($sigPath) }

# --- Body (NOTE: backtick-dollar for literal `$ in here-string) ---
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Frank,</p>

<p>Quick follow-up on our exchange this morning. I went back and worked the Section 5 cancellation-fee math more carefully against the actual per-month, per-category data from the reconciliation spreadsheets for both BST and VTD. I want you to have the same numbers I do, because the proper textual reading produces materially different results than the figures we have been working from.</p>

<p>BST is closed (Jeff accepted the `$12,443.95 monthlies-only deal at 12:12 PM today) - that is done and I am not raising it to relitigate. But the same clause governs VTD, and I want to make sure we are aligned on the methodology before any settlement movement with VTD's counsel.</p>

<h3 style="margin-bottom:6px">1. The clause language (Under Contract &para; 5 - same in both contracts)</h3>

<p style="margin-left:20px;border-left:3px solid #ccc;padding-left:12px;font-style:italic">"If this agreement is terminated, any hours that exceeded the previous under contract period average, that were documented through ticketing, will be charged at a rate of `$150 per hour and will be assessed as the cancellation fee to the client and due before agreement is terminated."</p>

<h3 style="margin-bottom:6px">2. The proper textual reading - three components</h3>

<p><strong>(a) "the previous under contract period average."</strong> Definite article + singular "period." This refers to the immediately preceding completed under-contract cycle. The contract uses 12-month under-contract periods (&para; 1) and explicitly handles the baseline reset in &para; 3: "The first month of the new average will be charged at the previous average since that invoice will be due the first of the month." So at any point in time after the first cycle, "the previous under contract period average" = the prior cycle's actual average, which is also the current cycle's billed baseline by operation of &para; 3.</p>

<p><strong>(b) "any hours that exceeded."</strong> Each month of a post-first-cycle period has a defined baseline (the rolled-forward prior-period average per &para; 3). For each such month, the hours that "exceeded" that baseline are the positive delta between actual ticketed hours and billed hours. Months where actual ran below the baseline contribute zero (no negative offset); &para; 4 handles those as credits separately.</p>

<p><strong>(c) "documented through ticketing."</strong> Both BST and VTD have full ticket-level time entries through PSA. This gating condition is satisfied for every month of both matters.</p>

<h3 style="margin-bottom:6px">3. Period 1 / Cycle 1 is excluded</h3>

<p>The first under-contract cycle has no "previous under contract period" - it is the first one. So &sect; 5 has no textual application to first-cycle months. Their excess (over the originally contracted baseline) was already amortized forward into the second cycle's billed baseline by &para; 3 - the customer paid for it prospectively at native rates over the second cycle. The cancellation fee at `$150 captures the cancellation premium on excess hours that were never paid for at any rate, which is what happens after the first cycle when actual exceeds the rolled-forward baseline.</p>

<p>Excluding Cycle 1 is the textual answer and the conservative answer. It is what opposing counsel will argue for and what we should be prepared to anchor at.</p>

<h3 style="margin-bottom:6px">4. The methodology in one sentence</h3>

<p style="margin-left:20px;font-weight:bold">For each month after the first complete cycle, take (actual hours minus billed hours) where positive; sum across all months and all categories; multiply by `$150; add the 10% late fee per Other Terms &para; 3.</p>

<h3 style="margin-bottom:6px">5. BST - applied (for the record; matter is closed)</h3>

<table style="border-collapse:collapse;font-family:$fontStack;font-size:11pt;margin-bottom:8px">
  <tr style="background:#f4f4f4">
    <th style="border:1px solid #ccc;padding:6px 10px;text-align:left">Category</th>
    <th style="border:1px solid #ccc;padding:6px 10px;text-align:left">Cycle</th>
    <th style="border:1px solid #ccc;padding:6px 10px;text-align:right">Actual hrs</th>
    <th style="border:1px solid #ccc;padding:6px 10px;text-align:right">Billed hrs</th>
    <th style="border:1px solid #ccc;padding:6px 10px;text-align:right">Monthly Positive</th>
  </tr>
  <tr><td style="border:1px solid #ccc;padding:4px 10px">Off-Shore Normal (`$15)</td><td style="border:1px solid #ccc;padding:4px 10px">2</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">679.13</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">354.00</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">325.13</td></tr>
  <tr><td style="border:1px solid #ccc;padding:4px 10px">Off-Shore After-Hours (`$30)</td><td style="border:1px solid #ccc;padding:4px 10px">2</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">404.45</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">189.96</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">218.75</td></tr>
  <tr><td style="border:1px solid #ccc;padding:4px 10px">Onshore Normal (`$125)</td><td style="border:1px solid #ccc;padding:4px 10px">2</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">115.68</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">99.72</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">32.74</td></tr>
  <tr><td style="border:1px solid #ccc;padding:4px 10px">All categories</td><td style="border:1px solid #ccc;padding:4px 10px">3</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">401.16</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">1,131.35</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right;font-weight:bold">0.00</td></tr>
  <tr style="background:#f4f4f4;font-weight:bold"><td style="border:1px solid #ccc;padding:4px 10px" colspan="4">Total monthly positive excess (Cycles 2 + 3)</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">576.62</td></tr>
</table>

<p style="margin-left:20px;font-family:Consolas,monospace;font-size:11pt;background:#f8f8f8;padding:8px;border-left:3px solid #ccc">
576.62 hrs &times; `$150 = `$86,493.00<br>
&nbsp;&nbsp;&nbsp;&nbsp;+ 10% late fee = `$ 8,649.30<br>
<strong>Proper BST Section 5 cancellation fee = `$95,142.30</strong>
</p>

<p>Cycle 3 ran under baseline every month (consistent with what you concluded earlier this morning). Cycle 2 is where the unpaid excess sat, because BST scaled up significantly from Cycle 1 baselines and Technijian never invoked &para; 4 monthly extras during the cycle.</p>

<p>Note: this is `$95,142.30, not `$126,442.50 (the figure on invoice #28064 - which used cumulative life-of-contract methodology that improperly included Cycle 1 excess) and not `$0 (your Cycle-3-only reading from earlier this morning). The right answer textually is `$95K. Settled at `$0 + monthlies, which I am content with given the litigation cost calculus, but I want VTD priced correctly.</p>

<h3 style="margin-bottom:6px">6. VTD - applied (this is what matters now)</h3>

<table style="border-collapse:collapse;font-family:$fontStack;font-size:11pt;margin-bottom:8px">
  <tr style="background:#f4f4f4">
    <th style="border:1px solid #ccc;padding:6px 10px;text-align:left">Category</th>
    <th style="border:1px solid #ccc;padding:6px 10px;text-align:left">Period</th>
    <th style="border:1px solid #ccc;padding:6px 10px;text-align:right">Actual hrs</th>
    <th style="border:1px solid #ccc;padding:6px 10px;text-align:right">Billed hrs</th>
    <th style="border:1px solid #ccc;padding:6px 10px;text-align:right">Monthly Positive</th>
  </tr>
  <tr><td style="border:1px solid #ccc;padding:4px 10px">Off-Shore Normal (`$15)</td><td style="border:1px solid #ccc;padding:4px 10px">P2 + P3</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">1,638.42</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">1,280.42</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">463.20</td></tr>
  <tr><td style="border:1px solid #ccc;padding:4px 10px">Off-Shore After-Hours (`$30)</td><td style="border:1px solid #ccc;padding:4px 10px">P2 + P3</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">1,112.60</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">1,068.91</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">191.57</td></tr>
  <tr><td style="border:1px solid #ccc;padding:4px 10px">Onshore Normal (`$125)</td><td style="border:1px solid #ccc;padding:4px 10px">P2 + P3</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">218.10</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">300.00</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">25.78</td></tr>
  <tr style="background:#f4f4f4;font-weight:bold"><td style="border:1px solid #ccc;padding:4px 10px" colspan="4">Total monthly positive excess (P2 + P3)</td><td style="border:1px solid #ccc;padding:4px 10px;text-align:right">680.55</td></tr>
</table>

<p style="margin-left:20px;font-family:Consolas,monospace;font-size:11pt;background:#f8f8f8;padding:8px;border-left:3px solid #ccc">
680.55 hrs &times; `$150 = `$102,082.50<br>
&nbsp;&nbsp;&nbsp;&nbsp;+ 10% late fee = `$ 10,208.25<br>
<strong>Proper VTD Section 5 cancellation fee = `$112,290.75</strong>
</p>

<p>Compare to the figures currently on the record:</p>

<ul>
  <li><strong>Demand on file (filed 10/23/2025):</strong> `$240,555.15 (with the `$67.65 late-fee arithmetic error)</li>
  <li><strong>Demand contract-correct:</strong> `$240,487.50</li>
  <li><strong>Proper textual reading (above):</strong> `$112,290.75</li>
</ul>

<p>The Demand overstates the proper textual figure by about `$128K. The Demand's 1,457.50 hours methodology is a derived intermediate figure that silently includes P1 excess that has no textual hook under &sect; 5 (P1 has no "previous under contract period" to compare against). The data points VTD's counsel will run independently are the same data points I just ran above; I expect them to land at this number or lower.</p>

<h3 style="margin-bottom:6px">7. Why this matters for VTD strategy</h3>

<p>The DAMAGES_SCENARIO_ANALYSIS internal memo set a `$125,000 walk-away floor based on probability-weighting that included `$0 (Scenario E1) at ~15%. Under the proper textual reading, the textual answer for VTD is `$112,290.75 - which sits below the walk-away floor. The probability-weighting needs to be revisited because what the memo treated as a tail-risk scenario is closer to the central case textually.</p>

<p>I see three options for VTD. I do not have a strong view on which is right, but I want your guidance:</p>

<ol>
  <li><strong>Hold the Demand at `$240,487.50 publicly</strong> and see whether VTD's counsel does the textual analysis. Settle in the `$150K-`$200K range before they get there. Risk: they run the numbers, anchor at `$112K, and we settle in the `$80K-`$110K range.</li>
  <li><strong>Amend the Demand under AAA Rule R-6 to `$112,290.75 + interest + fees</strong> and pursue a clean through-award position. Adds `$25K prejudgment interest from 7/27/2025 plus &sect; 5.02 / &sect; 1717 fees - realistic award `$150K-`$170K. Trades the high-anchor leverage for credibility and a defensible textual position.</li>
  <li><strong>Hybrid:</strong> hold the `$240,487.50 anchor, but quietly use `$112,290.75 internally as the new walk-away floor (replacing `$125K), and target a `$140K-`$170K landing zone.</li>
</ol>

<p>My instinct is option 3, but you know the AAA tribunal posture and Respondent's likely playbook better than I do.</p>

<h3 style="margin-bottom:6px">8. Independent leverage that is unaffected</h3>

<p>Whatever the &sect; 5 number is, the dual dispute-window waiver argument (~140 weekly zero-dollar invoices with 30-day windows + monthly invoices with 60-day &sect; 3.01 windows, zero objections across 27 months) still bars any "records aren't accurate" defense. That argument doesn't change based on the &sect; 5 reading. So whatever number we anchor at, the underlying ticket-hour reconciliation is locked in by course of performance and waiver. That keeps the textual `$112,290.75 figure floored at that number; opposing counsel cannot push to `$0 the way they could without the waiver record.</p>

<h3 style="margin-bottom:6px">9. What I am asking</h3>

<ol>
  <li>Confirm the &sect; 5 textual reading above tracks for you, or tell me where you disagree.</li>
  <li>Pick option 1, 2, or 3 above for VTD posture (or propose a fourth).</li>
  <li>Decide whether to amend the Demand under AAA Rule R-6 now (if option 2) or hold it (if 1 or 3).</li>
</ol>

<p>I would rather have this conversation now than discover the proper number mid-deposition. Available on cell at 714.402.3164 if it's easier to talk through.</p>

<p>Thank you, Frank.</p>

</div>
$sig
</body>
</html>
"@

# --- Connect ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Create draft ---
Write-Host "Creating draft..." -ForegroundColor Cyan
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter @{
    Subject      = $subject
    Body         = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @( @{ EmailAddress = @{ Address = $toEmail; Name = $toName } } )
    CcRecipients = @( @{ EmailAddress = @{ Address = $ccEmail; Name = $ccName } } )
}

Disconnect-MgGraph | Out-Null

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Yellow
Write-Host "DRAFT READY in Outlook Drafts (NOT sent)." -ForegroundColor Yellow
Write-Host "Open Outlook -> Drafts -> '$subject'" -ForegroundColor Yellow
Write-Host "Review, then click Send." -ForegroundColor Yellow
Write-Host "Draft Id: $($draft.Id)" -ForegroundColor Gray
Write-Host "=========================================================" -ForegroundColor Yellow
