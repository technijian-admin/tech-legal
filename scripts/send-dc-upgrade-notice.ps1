# ============================================================
# Send DC Network Upgrade Notice — Saturday April 18, 2026
# BCC all active client key contacts
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

# --- BCC list: one key contact per active client (70 clients, minus BST terminating, minus MAX internal) ---
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

$subject = "Scheduled Data Center Network Upgrade &mdash; Saturday, April 18 | Enhanced Security &amp; Redundancy"

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

<!-- Hero Banner -->
<table role="presentation" width="680" cellpadding="0" cellspacing="0" style="background:linear-gradient(135deg,#1A1A2E 0%,#006DB6 100%);border-radius:12px 12px 0 0;">
<tr><td style="padding:40px 50px;text-align:center;">
  <img src="https://technijian.com/wp-content/uploads/2026/03/technijian-logo-full-color-600x125-1.png" alt="Technijian" width="280" style="display:block;margin:0 auto 20px;" />
  <h1 style="margin:0;font-family:Aptos,Calibri,Helvetica,sans-serif;font-size:26px;font-weight:700;color:#ffffff;line-height:1.3;">
    Scheduled Data Center Network Upgrade
  </h1>
  <p style="margin:10px 0 0;font-family:Aptos,Calibri,Helvetica,sans-serif;font-size:16px;color:#B8D4E8;font-weight:400;">
    Saturday, April 18, 2026 &nbsp;|&nbsp; 9:00 AM &ndash; 6:00 PM Pacific
  </p>
</td></tr>
</table>

<!-- Body Content -->
<table role="presentation" width="680" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:0 0 12px 12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
<tr><td style="padding:40px 50px;font-family:Aptos,Calibri,Helvetica,sans-serif;font-size:12pt;color:#333333;line-height:1.6;">

<p style="margin:0 0 16px;">Dear Valued Client,</p>

<p style="margin:0 0 16px;">
I'm writing to let you know about a <strong>scheduled data center network upgrade</strong> we're performing this
<strong>Saturday, April 18, 2026</strong>, between <strong>9:00 AM and 6:00 PM Pacific Time</strong>.
</p>

<!-- WHY Section -->
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:20px 0;background-color:#F0F7FC;border-left:4px solid #006DB6;border-radius:0 8px 8px 0;">
<tr><td style="padding:20px 24px;">
<h2 style="margin:0 0 10px;font-size:15px;color:#006DB6;font-weight:700;">WHY WE'RE DOING THIS</h2>
<p style="margin:0;font-family:Aptos,Calibri,Helvetica,sans-serif;font-size:12pt;color:#333;line-height:1.6;">
Following the service disruption we experienced in September, we conducted a thorough root-cause analysis of our
data center network architecture. That review identified single points of failure in our core switching and storage
connectivity that contributed to the outage &mdash; and also highlighted opportunities to significantly strengthen
how management and storage networks are accessed. This upgrade addresses both.
</p>
</td></tr>
</table>

<!-- WHAT'S CHANGING Section -->
<h2 style="margin:24px 0 16px;font-size:16px;color:#1A1A2E;font-weight:700;border-bottom:2px solid #F67D4B;padding-bottom:8px;">
WHAT'S CHANGING
</h2>

<!-- Card: Redundant Network Paths -->
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 12px;background-color:#FAFAFA;border-radius:8px;border:1px solid #E8E8E8;">
<tr>
<td width="6" style="background-color:#006DB6;border-radius:8px 0 0 8px;"></td>
<td style="padding:16px 20px;">
<h3 style="margin:0 0 6px;font-size:13px;color:#006DB6;font-weight:700;">REDUNDANT NETWORK PATHS</h3>
<p style="margin:0;font-size:11pt;color:#555;line-height:1.5;">
We're rebalancing storage and compute connections across both core switches, eliminating the single-switch
dependency that was a factor in September's outage.
</p>
</td>
</tr>
</table>

<!-- Card: Modern Routing -->
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 12px;background-color:#FAFAFA;border-radius:8px;border:1px solid #E8E8E8;">
<tr>
<td width="6" style="background-color:#006DB6;border-radius:8px 0 0 8px;"></td>
<td style="padding:16px 20px;">
<h3 style="margin:0 0 6px;font-size:13px;color:#006DB6;font-weight:700;">MODERN ROUTING ARCHITECTURE</h3>
<p style="margin:0;font-size:11pt;color:#555;line-height:1.5;">
Layer 3 routing is migrating from our legacy access switch to purpose-built Nexus switches with HSRP failover.
If one switch fails, traffic automatically moves to the standby &mdash; no manual intervention required.
</p>
</td>
</tr>
</table>

<!-- Card: Network Isolation -->
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 12px;background-color:#FAFAFA;border-radius:8px;border:1px solid #E8E8E8;">
<tr>
<td width="6" style="background-color:#006DB6;border-radius:8px 0 0 8px;"></td>
<td style="padding:16px 20px;">
<h3 style="margin:0 0 6px;font-size:13px;color:#006DB6;font-weight:700;">STRONGER NETWORK ISOLATION</h3>
<p style="margin:0;font-size:11pt;color:#555;line-height:1.5;">
New VLAN isolation ACLs will enforce strict segmentation between client environments, improving both
security posture and compliance alignment.
</p>
</td>
</tr>
</table>

<!-- Card: Streamlined Internet -->
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 12px;background-color:#FAFAFA;border-radius:8px;border:1px solid #E8E8E8;">
<tr>
<td width="6" style="background-color:#006DB6;border-radius:8px 0 0 8px;"></td>
<td style="padding:16px 20px;">
<h3 style="margin:0 0 6px;font-size:13px;color:#006DB6;font-weight:700;">STREAMLINED INTERNET PATH</h3>
<p style="margin:0;font-size:11pt;color:#555;line-height:1.5;">
A dedicated transit VLAN between our firewall and core switches replaces the previous multi-hop path,
reducing latency and simplifying our security perimeter.
</p>
</td>
</tr>
</table>

<!-- Card: Zero-Trust -->
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 12px;background-color:#FFF8F5;border-radius:8px;border:1px solid #F6D4C4;">
<tr>
<td width="6" style="background-color:#F67D4B;border-radius:8px 0 0 8px;"></td>
<td style="padding:16px 20px;">
<h3 style="margin:0 0 6px;font-size:13px;color:#F67D4B;font-weight:700;">ZERO-TRUST ACCESS TO MANAGEMENT &amp; STORAGE NETWORKS</h3>
<p style="margin:0;font-size:11pt;color:#555;line-height:1.5;">
We are introducing a new security layer for all access to management and storage infrastructure. These critical
networks will now be accessible <strong>exclusively through CloudBrink SDWAN</strong>, which requires:
</p>
<ul style="margin:10px 0 0;padding-left:20px;font-size:11pt;color:#555;line-height:1.6;">
<li><strong>Azure AD Single Sign-On (SSO)</strong> &mdash; Every technician must authenticate through Azure AD,
enforcing MFA and conditional access policies.</li>
<li><strong>Device Enrollment</strong> &mdash; Only enrolled, policy-compliant devices are permitted to connect.
Unmanaged or unknown devices are blocked at the network edge.</li>
</ul>
<p style="margin:10px 0 0;font-size:11pt;color:#555;line-height:1.5;">
As part of this change, <strong>management and storage network access is being removed from Technijian MyRemote
(ScreenConnect)</strong>. This broad access path is being permanently retired. CloudBrink's SDWAN tunnel provides
encrypted, identity-verified, device-verified connectivity &mdash; a significant step up in security posture over
traditional remote access tools.
</p>
</td>
</tr>
</table>

<!-- Card: DNS Migration -->
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 12px;background-color:#F0FAF7;border-radius:8px;border:1px solid #C4E8DC;">
<tr>
<td width="6" style="background-color:#1EAAC8;border-radius:8px 0 0 8px;"></td>
<td style="padding:16px 20px;">
<h3 style="margin:0 0 6px;font-size:13px;color:#1EAAC8;font-weight:700;">HOSTED WEBSITE DNS MIGRATION TO LAS VEGAS DATACENTER</h3>
<p style="margin:0;font-size:11pt;color:#555;line-height:1.5;">
For clients with websites hosted on our infrastructure, we will be migrating DNS entries to point to our
<strong>Las Vegas datacenter</strong> during this maintenance window. This provides geographic redundancy for your
web presence &mdash; your hosted sites will be served from our Vegas facility, independent of the Irvine datacenter,
so a future network event at one location does not take your public-facing website offline. DNS propagation typically
completes within a few hours, and we will verify resolution from multiple regions before closing out.
</p>
</td>
</tr>
</table>

<!-- WHAT TO EXPECT Section -->
<h2 style="margin:24px 0 16px;font-size:16px;color:#1A1A2E;font-weight:700;border-bottom:2px solid #006DB6;padding-bottom:8px;">
WHAT TO EXPECT
</h2>

<p style="margin:0 0 12px;">
You may experience <strong>intermittent connectivity disruptions</strong> during the maintenance window as we recable
and reconfigure network equipment. Clients with hosted websites should expect a brief period of DNS propagation
(typically 1&ndash;4 hours) during which your site may intermittently resolve to the old or new address &mdash; this is
normal and resolves automatically.
</p>
<p style="margin:0 0 12px;">
We've structured the work in phases with verification checkpoints at each stage, and a full rollback plan is in place
if needed. Services are expected to be <strong>fully restored by 6:00 PM Pacific</strong> at the latest, though we
anticipate completing ahead of schedule.
</p>

<!-- ACTION REQUIRED Section -->
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:20px 0;background-color:#FFF8F5;border:1px solid #F6D4C4;border-radius:8px;">
<tr><td style="padding:20px 24px;">
<h2 style="margin:0 0 10px;font-size:15px;color:#F67D4B;font-weight:700;">WHAT YOU NEED TO DO</h2>
<p style="margin:0;font-family:Aptos,Calibri,Helvetica,sans-serif;font-size:12pt;color:#333;line-height:1.6;">
No action is required on your part. If you have any time-sensitive operations scheduled for Saturday, or if you manage
your own DNS and need to coordinate the cutover, please let us know by <strong>Friday, April 17</strong> so we can
plan accordingly.
</p>
</td></tr>
</table>

<p style="margin:0 0 12px;">
If you have any questions or concerns, please don't hesitate to reach out to our support team at
<strong>949.379.8501</strong> or reply to this email.
</p>

<p style="margin:0 0 0;">
Thank you for your continued trust in Technijian. Investments like these &mdash; in redundancy, zero-trust security,
and geographic resilience &mdash; are how we ensure the reliability and protection you depend on.
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

# --- Create draft (BCC requires draft approach) ---
Write-Host "Creating draft message..."
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter @{
    Subject       = "Scheduled Data Center Network Upgrade - Saturday, April 18 | Enhanced Security and Redundancy"
    Body          = @{ ContentType = "HTML"; Content = $htmlBody }
    BccRecipients = $bccRecipients
}

Write-Host "Draft created: $($draft.Id)"
Write-Host "BCC count: $($bccAddresses.Count) recipients"

# --- Send ---
Write-Host "Sending..."
Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
Write-Host "SENT successfully to $($bccAddresses.Count) BCC recipients."

Disconnect-MgGraph | Out-Null
