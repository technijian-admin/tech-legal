# ============================================================
# Data Center Upgrade Follow-Up — Post-Incident Notice
# Saturday April 18, 2026 upgrade: extended window + root cause
# BCC all active client key contacts (same list as send-dc-upgrade-notice.ps1)
# Creates Graph draft in RJain's Drafts folder. Does NOT auto-send.
# ============================================================

# --- Auth ---
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

$senderUpn = "RJain@technijian.com"

# --- Signature ---
$signature = Get-Content "c:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html" -Raw -Encoding UTF8

# --- BCC list: one key contact per active client (same list as pre-upgrade notice) ---
$bccAddresses = @(
    "kmaahs@patientcaremedical.com",          # PCM - 180 Medical
    "ckramer@acuityadvisors.com",             # ACU - Acuity Advisors
    "bgoldcole@gmail.com",                    # ASC - Adsys Controls
    "Deepak@algrointernational.com",          # ALG - Algro International
    "rami.hammouri@aleragroup.com",           # ALE - Alera Group
    "iris.liu@americanfundstars.com",         # AFFG - American Fundstars
    "dave@andersenmp.com",                    # ANI - Andersen Industries
    "cordero@aaoc.com",                       # AOC - Apartment Assoc OC
    "melissa@aventine-apartments.com",        # AAVA - Aventine Aliso Viejo
    "mike@ayresgroup.net",                    # AYH - Ayers Hotels
    "keith@b2insurance.com",                  # B2I - B2 Insurance (swapped 2026-04-21 from brenna@b2insurance.com which bounced 5.1.1 on 2026-04-16 and 2026-04-20; see bounce-register.md)
    "info@tellustile.com",                    # BBTS - BB Tile and Stone
    "matt@bobergeng.com",                     # BBE - Boberg Engineering
    "rakeshr@bromic.com",                     # BRM - Bromic
    "bryan@burkhartbros.com",                 # BBC - Burkhart Brothers
    "dave@brandywine-homes.com",              # BWH - Brandywine Homes
    "chris@chrisblanklaw.com",                # CBL - Chris Bank Law
    "jason.w@cbinteriors.net",                # CBI - Christian Brothers
    "kennyt@coastaero.com",                   # CAM - Coast Aero Mfg
    "tj@corebenefits.org",                    # COB - Core Benefits
    "khartshorn@culpco.com",                  # CCC - Culp Construction
    "jcheng@customsiliconsolutions.com",      # CSS - Custom Silicon
    "josh@disruptixtalent.com",               # DTS - Disruptix Talent
    # REMOVED 2026-04-20: nellis@cfiemail.com (EAG) - NDR 550 5.x mailbox unavailable
    "basalcell@hotmail.com",                  # EBRMD - Ernest Robinson MD
    "salamonjeffrey@tartanofredlands.com",    # FOR - Falconer of Redlands
    "jaydai17@gmail.com",                     # R_GD - George Dai
    "danielf@lwsb.com",                       # GRF - Golden Rain Foundation
    "danny@gsdsolutions.io",                  # GSD - GSD Solutions
    "maritza.a@housingforhealthoc.org",       # HHOC - Housing for Health OC
    "ap@hotelnormandiela.com",                # NOR - Hotel Normandie
    "hung.lam@HuLa-IT.com",                  # HIT - Hula IT Services
    "jack@icmlending.com",                    # ICML - ICM Lending
    "sdkamm@yahoo.com",                      # ISI - Intl Sportsmedicine
    "donald@jdhpacific.com",                  # JDH - JDH Pacific
    "scott.haney@jerryseiner.com",            # JSD - Jerry Seiner
    "heather@kes-homes.com",                  # KES - KES Homes
    "knelsen@kabukisprings.com",              # KSS - Kabuki Springs
    "patsythom@aol.com",                      # KRLMD - Kenneth Lynn MD
    "nengland@kivacc.com",                    # KCC - Kiva Container
    # REMOVED 2026-04-20: anthony@krugerandeckels.com (KEI) - NDR 550 5.x mailbox unavailable
    "dchesley@chesleylawyers.com",            # LODC - Law Offices David Chesley
    "stephen@ABRAHAM-LAWOFFICES.COM",         # FAL - Law Offices Stephen Abraham
    "aport@loganadgroup.com",                 # LAG - Logan Advertising
    "Estrada@magnespec.com",                  # MGN - Magnespec
    "natalie@miraculousminds.com",            # MRM - MiraculousMinds
    # REMOVED 2026-04-20: sammy@natautocoverage.com (NAC) - NDR 550 5.4.310 DNS domain natautocoverage.com does not exist (domain dead)
    "cbraun@oneoc.org",                       # ONE - OneOC
    "BVarner@orthoxpress.com",                # ORX - Ortho Xpress
    "chris@petcp.com",                        # PCAP - Pet Care Plus
    "George@promed-financial.com",            # PMF - Premed Financial
    "kathy@richardcalterlawfirm.com",         # RALF - Richard Alter Law
    "rg@rkengineer.com",                      # RKEG - RK Engineering
    "raul@roarservices.com",                  # RBS - Roar Building
    "jtroutman@richlandinvestments.com",      # RMG - Roddel Marketing
    "alagrosa@yahoo.com",                     # RSPMD - Rosalina See-Prats MD
    "lbjendo@mac.com",                        # SVE - Saddleback Valley Endo
    "carol@siegeconsulting.com",              # SGC - Siege Consulting
    "fant.la@ssci2global.com",               # SSCI - SSCI Inc
    "bobby@stwautosports.com",               # STW - STW Autosports
    "kevin@strategicairservices.com",         # SAS - Strategic Air Services
    "rob@talleyassoc.com",                    # TALY - Talley and Associates
    "salamonjeffrey@tartanofredlands.com",    # TOR - Tartan of Redlands
    # REMOVED 2026-04-20: DANIEL@TORCHENTERPRISE.COM (TCH) - NDR 5.1.1 recipient not found in Office 365
    "james@usfifoods.com",                    # USFI - USFI Inc
    "aaron.kyllander@viaautofinance.com",     # VAF - Via Auto Finance
    "colleen@vintagegroupre.com",             # VG - Vintage Group
    "dmitriy@wcshipping.com"                  # WCS - West Coast Shipping
)

# Deduplicate (FOR and TOR share same contact)
$bccAddresses = $bccAddresses | Select-Object -Unique

$subject = "Data Center Upgrade Follow-Up - Service Impact, Root Cause, and Resolution"

$htmlBody = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;background-color:#f4f5f7;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f5f7;">
<tr><td align="center" style="padding:30px 10px;">

<!-- Hero Banner - white bg with colored accent stripe (Outlook-safe; no gradient) -->
<table role="presentation" width="680" cellpadding="0" cellspacing="0" bgcolor="#ffffff" style="background-color:#ffffff;border-radius:12px 12px 0 0;">
<tr><td bgcolor="#006DB6" style="background-color:#006DB6;height:6px;line-height:6px;font-size:1px;border-radius:12px 12px 0 0;">&nbsp;</td></tr>
<tr><td style="padding:40px 50px 30px;text-align:center;">
  <img src="https://technijian.com/wp-content/uploads/2026/03/technijian-logo-full-color-600x125-1.png" alt="Technijian" width="280" style="display:block;margin:0 auto 20px;" />
  <h1 style="margin:0;font-family:Aptos,Calibri,Helvetica,sans-serif;font-size:26px;font-weight:700;color:#1A1A2E;line-height:1.3;">
    Data Center Upgrade &mdash; Follow-Up
  </h1>
  <p style="margin:10px 0 0;font-family:Aptos,Calibri,Helvetica,sans-serif;font-size:16px;color:#006DB6;font-weight:500;">
    Saturday, April 18, 2026 &nbsp;|&nbsp; Service Impact, Root Cause &amp; Resolution
  </p>
</td></tr>
</table>

<!-- Body Content -->
<table role="presentation" width="680" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:0 0 12px 12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
<tr><td style="padding:40px 50px;font-family:Aptos,Calibri,Helvetica,sans-serif;font-size:12pt;color:#333333;line-height:1.6;">

<p style="margin:0 0 16px;">Dear Valued Client,</p>

<p style="margin:0 0 16px;">
Following my earlier note about Saturday's data center upgrade, I want to give you a complete picture of the day
&mdash; including an issue that affected phone service after the main work was complete.
</p>

<!-- APOLOGY Callout -->
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:20px 0;background-color:#F0F7FC;border-left:4px solid #006DB6;border-radius:0 8px 8px 0;">
<tr><td style="padding:20px 24px;">
<p style="margin:0;font-family:Aptos,Calibri,Helvetica,sans-serif;font-size:12pt;color:#333;line-height:1.6;">
<strong>First, I want to apologize.</strong> The maintenance window was scheduled to close at 6:00 PM Pacific and
instead ran two hours longer, until <strong>8:00 PM Pacific</strong>, while we resolved a post-cutover issue with
inbound call routing. I know many of you depend on uninterrupted service, and a two-hour overrun is not acceptable
to us either. Thank you for your patience while we saw it through.
</p>
</td></tr>
</table>

<!-- WHAT HAPPENED -->
<h2 style="margin:24px 0 16px;font-size:16px;color:#1A1A2E;font-weight:700;border-bottom:2px solid #006DB6;padding-bottom:8px;">
WHAT HAPPENED
</h2>
<p style="margin:0 0 12px;">
Because the 3CX phone system is critical to your call flow, we migrated the 3CX server to a <strong>temporary host</strong>
before the upgrade began so it would stay online through the entire network change. That part went exactly as planned
&mdash; call service remained operational throughout the scheduled window.
</p>
<p style="margin:0 0 12px;">
When we moved the 3CX server back to its permanent facility after the upgrade, inbound calls began failing to reach
the phone system, even though 3CX itself was healthy and our carriers were sending traffic normally.
</p>

<!-- ROOT CAUSE -->
<h2 style="margin:24px 0 16px;font-size:16px;color:#1A1A2E;font-weight:700;border-bottom:2px solid #F67D4B;padding-bottom:8px;">
ROOT CAUSE
</h2>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 16px;background-color:#FFF8F5;border-radius:8px;border:1px solid #F6D4C4;">
<tr>
<td width="6" style="background-color:#F67D4B;border-radius:8px 0 0 8px;"></td>
<td style="padding:16px 20px;">
<p style="margin:0;font-size:12pt;color:#333;line-height:1.6;">
Our engineering team verified the 3CX configuration, reviewed detailed system logs, and worked directly with the DID
providers &mdash; the carriers that route your phone numbers to us &mdash; to trace the call path. They confirmed their
call invitations were <strong>not reaching our public IP address</strong>. Working through the firewall, we identified
the cause: the firewall's address resolution cache (ARP/MAC table) was still holding the binding from the temporary
host and had not refreshed after the cutover back to the permanent facility. In plain terms &mdash; the firewall was
still routing inbound call traffic to where 3CX used to sit, not where it had returned to.
</p>
</td>
</tr>
</table>

<!-- RESOLUTION -->
<h2 style="margin:24px 0 16px;font-size:16px;color:#1A1A2E;font-weight:700;border-bottom:2px solid #006DB6;padding-bottom:8px;">
RESOLUTION
</h2>
<p style="margin:0 0 12px;">
Because we maintain <strong>dual firewalls for redundancy</strong>, we performed a controlled reboot of each firewall
<em>in sequence</em> &mdash; one at a time, never both at once &mdash; to clear the stale entries without introducing
any additional outage. Once the caches refreshed, inbound call invitations reached 3CX immediately.
</p>
<p style="margin:0 0 12px;">
We then verified <strong>all inbound and outbound call flows across every DID provider</strong> before declaring the
window closed at 8:00 PM Pacific.
</p>

<!-- CLOSE -->
<p style="margin:24px 0 12px;">
Again, my apologies for the extended window. If you've noticed any lingering call behavior since Saturday &mdash;
missed inbound calls, one-way audio, or anything else that doesn't feel right &mdash; please let our team know at
<strong>949.379.8501</strong> or reply to this email, and we'll investigate immediately.
</p>

<p style="margin:0 0 0;">
Thank you, as always, for your trust and your patience.
</p>

</td></tr>
</table>

</td></tr>
</table>
</body>
</html>
'@

# Append signature
$htmlBody = $htmlBody.Replace("</body></html>", "$signature</body></html>")

# --- Build BCC recipients array ---
$bccRecipients = @()
foreach ($addr in $bccAddresses) {
    $bccRecipients += @{ EmailAddress = @{ Address = $addr } }
}

# --- Create draft only (DO NOT auto-send; user reviews in Outlook and clicks Send) ---
Write-Host "Creating draft message..."
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter @{
    Subject       = $subject
    Body          = @{ ContentType = "HTML"; Content = $htmlBody }
    BccRecipients = $bccRecipients
}

Write-Host ""
Write-Host "DRAFT CREATED (not sent)."
Write-Host "  Subject:    $subject"
Write-Host "  From:       $senderUpn"
Write-Host "  BCC count:  $($bccAddresses.Count) recipients"
Write-Host "  Draft ID:   $($draft.Id)"
Write-Host ""
Write-Host "Open Outlook -> Drafts folder to review and send."

Disconnect-MgGraph | Out-Null