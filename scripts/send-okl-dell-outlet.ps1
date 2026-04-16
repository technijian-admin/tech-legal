# Send Dell Outlet pricing request for Oaktree Law server refresh
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">

<p>Hi Aadarsh and Dell Outlet Team,</p>

<p>Technijian is preparing a hardware refresh proposal for one of our managed-services clients (Oaktree Law) who is replacing their aging Dell PowerEdge server (service tag <strong>2KPZZV2</strong>). We have identified three candidate SKUs from the current Dell Outlet inventory and would like to request <strong>best possible pricing</strong> on each, with a <strong>48-hour hold / formal quote</strong> so we can present options to the client within that window.</p>

<p>Our Technijian account information is on file &#8212; please reference it directly; no need to request any additional details from our side.</p>

<h3 style="color:rgb(0,109,182); margin-bottom:4px">SKUs for pricing</h3>

<p><strong>1. Dell PowerEdge R760 (Refurbished) &#8212; Primary candidate</strong><br>
<strong>Outlet SKU:</strong> <code>POW0194278-R0031296-SA</code><br>
Config: 2x Intel Xeon Silver 4509Y (8C each, 4.10 GHz, 22.5M cache, 125W); 256 GB DDR5-5600 (4x 64 GB RDIMM Dual Rank); 5x 1.2 TB 10K SAS + 2x 480 GB M.2 NVMe boot + 960 GB SSD; Broadcom 5720 1 GbE OCP + 2x Broadcom 57416 10 GbE; 800W (1+1) redundant PSU; PERC H755 SAS Front; 2U Standard Bezel; 3-Year Basic Hardware Warranty 5x10 NBD Onsite.</p>

<p><strong>2. Dell PowerEdge R650 (Refurbished) &#8212; Alternate</strong><br>
<strong>Outlet SKU:</strong> <code>POW0193711-R0031036-SA</code><br>
Config: 2x Intel Xeon Gold 6346 (16C each, 3.60 GHz, 36M cache, 205W); 512 GB DDR4-3200 (16x 32 GB RDIMM Dual Rank); 2x 1.2 TB 10K SAS; 2x Broadcom 57414 10/25 GbE LP + Broadcom 57504 Quad-port 10/25 GbE OCP; redundant PSU; 1U LCD Bezel; 3-Year Basic Hardware Warranty 5x10 NBD Onsite.</p>

<p><strong>3. Dell PowerEdge XR7620 (Refurbished) &#8212; Alternate</strong><br>
<strong>Outlet SKU:</strong> <code>POW0193712-R0028403-SA</code><br>
Config: 2x Intel Xeon Gold 6426Y (16C each, 4.10 GHz, 37.5M cache, 185W); 256 GB DDR5-5600 (16x 16 GB RDIMM Single Rank); 2x 3.84 TB PCIe U.2 NVMe ISE DC RI Gen 4 + 2x 480 GB M.2 NVMe boot; Broadcom 5720 Quad-port 1 GbE OCP; redundant PSU; 2U NAF Bezel; 3-Year Basic Hardware Warranty 5x10 NBD Onsite.</p>

<h3 style="color:rgb(0,109,182); margin-bottom:4px">Additional quote items &#8212; please include for each SKU above</h3>

<p><strong>1. ProSupport tier options</strong> (line-itemed so we can compare):</p>
<ul>
<li><strong>3-Year Dell ProSupport</strong> (upgrade from included 3-Year Basic)</li>
<li><strong>5-Year Dell ProSupport</strong> (full 5-year coverage, 24x7 tech support, next-business-day onsite parts &amp; labor)</li>
<li><strong>5-Year Dell ProSupport Plus</strong> (if available &#8212; adds 4-hour mission-critical response, proactive/predictive monitoring, SupportAssist)</li>
</ul>

<p><strong>2. Microsoft licensing</strong> (please bundle with each server SKU):</p>
<ul>
<li><strong>10x Windows Server 2025 User CALs</strong> (per-user CALs)</li>
<li><strong>5x Windows Server 2025 Remote Desktop Services (RDP) User CALs</strong></li>
<li><strong>1x Windows Server 2025 Standard OEM (16-core) &#8212; ROK license</strong></li>
<li>Additional 2-core Windows Server Standard packs if the CPU config on the SKU exceeds 16 cores</li>
</ul>

<p><strong>3. Storage add-on options for the R760 (SKU #1) and R650 (SKU #2):</strong> if there is capacity to add drives from the factory, please quote pricing to bring usable RAID storage to approximately <strong>8 TB usable</strong> on each SKU.</p>

<p><strong>4. Accessories:</strong></p>
<ul>
<li>Dell ReadyRails II sliding rails (if not already included)</li>
<li>Cable management arm</li>
<li>iDRAC9 Enterprise upgrade (if currently Express)</li>
</ul>

<h3 style="color:rgb(0,109,182); margin-bottom:4px">Requested response</h3>

<ol>
<li><strong>Best possible pricing</strong> per SKU, including any current Outlet discount promotions</li>
<li>Add-on pricing for the items above, line-itemed</li>
<li>Estimated availability and ship lead time</li>
<li>Any <strong>better-configured alternatives</strong> currently on the Dell Outlet floor that match or exceed the above specs at a similar or lower price point &#8212; we are open to substitutions if there is better value available today</li>
<li><strong>Formal quote with the standard 48-hour hold</strong> so we can confirm with the client inside that window</li>
</ol>

<p><strong>Client context:</strong> small law firm (Oaktree Law, ~10 users) &#8212; primary file server with light virtualization. Replacing an out-of-warranty 14th-gen PowerEdge.</p>

<p>Thank you &#8212; please reach out if you need any additional context on the configurations.</p>

</div>

<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"><br></div>
<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">Thank you,</div>
<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"><br></div>

<table cellspacing="0" cellpadding="0" border="0" style="max-width:600px">
<tbody>
<tr><td colspan="2" style="border-top:3px solid rgb(246,125,75); padding-bottom:16px"></td></tr>
<tr>
<td style="padding-right:16px; vertical-align:top; width:120px">
<img alt="Ravi Jain" width="120" height="120" src="https://technijian.com/wp-content/uploads/2026/03/ravi-jain.jpg" style="width:120px; height:120px; border:2px solid rgb(233,236,239); border-radius:6px; display:block">
</td>
<td style="vertical-align:top">
<table cellspacing="0" cellpadding="0" border="0">
<tbody>
<tr><td style="line-height:1.3; padding-bottom:1px; color:rgb(26,26,46)">
<div style="line-height:1.3; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:18px"><span style="font-weight:700">Ravi Jain</span></div>
</td></tr>
<tr><td style="padding-bottom:2px; color:rgb(0,109,182)">
<div style="font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:13px"><span style="font-weight:600">CEO</span></div>
</td></tr>
<tr><td style="padding-bottom:8px; color:rgb(89,89,91)">
<div style="font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:12px">Technijian</div>
</td></tr>
<tr><td style="line-height:1.7; color:rgb(89,89,91)">
<div style="line-height:1.7; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif">
<span style="font-size:12px; color:rgb(0,109,182); font-weight:600">T:</span>&nbsp;<span style="font-size:12px; color:rgb(89,89,91)">949.379.8499 x201</span><br>
<span style="font-size:12px; color:rgb(0,109,182); font-weight:600">C:</span>&nbsp;<span style="font-size:12px; color:rgb(89,89,91)">714.402.3164</span><br>
<span style="font-size:12px; color:rgb(0,109,182); font-weight:600">S:</span>&nbsp;<span style="font-size:12px; color:rgb(89,89,91)">949.379.8501</span>&nbsp;<span style="font-size:11px; color:rgb(173,181,189)">(support)</span><br>
<span style="font-size:12px; color:rgb(0,109,182); font-weight:600">E:</span>&nbsp;<a href="mailto:rjain@technijian.com" style="font-size:12px; color:rgb(0,109,182); text-decoration:none">rjain@technijian.com</a><br>
<span style="font-size:12px; color:rgb(0,109,182); font-weight:600">W:</span>&nbsp;<a href="https://technijian.com" style="font-size:12px; color:rgb(0,109,182); text-decoration:none">technijian.com</a>
</div>
</td></tr>
<tr><td style="line-height:1.6; padding-top:10px; color:rgb(173,181,189)">
<div style="line-height:1.6; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:11px">
<span style="color:rgb(0,109,182); font-weight:600">USA:</span>&nbsp;18 Technology Dr., Ste 141, Irvine, CA 92618<br>
<span style="color:rgb(0,109,182); font-weight:600">India:</span>&nbsp;Plot No. 07, 1st Floor, Panchkula IT Park, Panchkula, Haryana 134109
</div>
</td></tr>
</tbody></table>
</td>
</tr>
<tr><td colspan="2" style="padding-top:14px; padding-bottom:10px">
<table cellspacing="0" cellpadding="0" border="0" style="width:100%"><tbody><tr><td style="border-top:2px solid rgb(0,109,182)"></td></tr></tbody></table>
</td></tr>
<tr><td colspan="2" style="padding-bottom:10px">
<img alt="Technijian" width="160" src="https://technijian.com/wp-content/uploads/2026/03/technijian-logo-full-color-600x125-1.png" style="width:160px; display:block">
</td></tr>
<tr><td colspan="2" style="border-top:1px solid rgb(233,236,239); padding-top:8px">
<p style="line-height:1.4; margin:0px; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:10px; color:rgb(173,181,189)">This email and any attachments are confidential and intended solely for the addressee. If you have received this message in error, please notify the sender immediately and delete it from your system. Unauthorized review, use, disclosure, or distribution is prohibited.</p>
</td></tr>
</tbody>
</table>

</body>
</html>
"@

$params = @{
    Message = @{
        Subject = "Pricing Request - 3 PowerEdge SKUs + Licensing + ProSupport (48-Hour Quote Hold)"
        Body = @{
            ContentType = "HTML"
            Content = $htmlBody
        }
        ToRecipients = @(
            @{ EmailAddress = @{ Address = "DellOutlet_ASG@Dell.com"; Name = "Dell Outlet ASG" } }
        )
        CcRecipients = @(
            @{ EmailAddress = @{ Address = "Aadarsh.Sultania@dell.com"; Name = "Sultania, Aadarsh" } }
        )
    }
    SaveToSentItems = $true
}

Send-MgUserMail -UserId "RJain@technijian.com" -BodyParameter $params
Write-Host "Email sent: To DellOutlet_ASG@Dell.com; Cc Aadarsh.Sultania@dell.com" -ForegroundColor Green
