# Send BWH Executive Summary email to Dave Barisic with proper Ravi Jain signature
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

$htmlBody = @"
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
</head>
<body dir="ltr">
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">

<p>Hi Dave,</p>

<p>Thank you for the opportunity to continue partnering with Brandywine Homes on your managed IT services. As discussed, I've prepared an Executive Summary that outlines the transition from the current Terms &amp; Conditions to a formal Master Service Agreement (MSA).</p>

<p>The attached summary highlights three key improvements effective May 1, 2026:</p>

<ul>
<li><strong>Desktop optimization</strong> &#8212; Updated count from 41 to 32 endpoints</li>
<li><strong>Service streamlining</strong> &#8212; Removed redundant Network Assessment (covered by Site Assessment)</li>
<li><strong>15% Virtual Staff rate reduction</strong> &#8212; Applied across all support roles</li>
</ul>

<p>These changes bring your monthly investment from <strong>&#36;9,041.05 to &#36;7,935.69</strong>, a savings of <strong>&#36;1,105.36/month (12.2%)</strong>.</p>

<p>The summary also includes an Unpaid Hours Recovery Plan to address the accumulated balance over the 12-month billing cycle. We will target utilizing approximately 20% fewer hours than billed each month to bring down the unpaid balance.</p>

<p>I'll be sending the MSA for signature via DocuSign shortly. Please review the Executive Summary and let me know if you have any questions.</p>

</div>

<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"><br></div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">Thank you,</div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"><br></div>

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
<tr><td style="padding-top:8px; padding-bottom:4px">
<table cellspacing="0" cellpadding="0" border="0"><tbody><tr>
<td style="padding-right:8px">
<a href="https://outlook.office.com/bookwithme/user/ceb349088c264d73b4854612958471e9@technijian.com/meetingtype/SVRwCe7HMUGxuT6WGxi68g2?anonymous&amp;ismsaljsauthenabled&amp;ep=mLinkFromTile" style="color:rgb(255,255,255); text-decoration:none; display:inline-block; padding:6px 16px; background-color:rgb(0,109,182); border-radius:4px; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:12px; font-weight:600">Book a Meeting</a>
</td>
<td>
<a href="https://outlook.office365.com/owa/calendar/Meetingwithsupport@Technijian365.onmicrosoft.com/bookings/" style="color:rgb(255,255,255); text-decoration:none; display:inline-block; padding:6px 16px; background-color:rgb(246,125,75); border-radius:4px; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:12px; font-weight:600">Book time with Support</a>
</td>
</tr></tbody></table>
</td></tr>
<tr><td style="line-height:1.6; padding-top:6px; color:rgb(173,181,189)">
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
<img alt="Technijian - Technology as a Solution" width="160" src="https://technijian.com/wp-content/uploads/2026/03/technijian-logo-full-color-600x125-1.png" style="width:160px; display:block">
</td></tr>
<tr><td colspan="2" style="padding-bottom:12px">
<div style="line-height:1; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:11px">
<a href="https://www.linkedin.com/company/technijian" style="color:rgb(0,109,182); text-decoration:none; font-weight:600">LinkedIn</a>&nbsp;<span style="color:rgb(233,236,239)">|</span>&nbsp;<a href="https://www.facebook.com/Technijian01/" style="color:rgb(0,109,182); text-decoration:none; font-weight:600">Facebook</a>&nbsp;<span style="color:rgb(233,236,239)">|</span>&nbsp;<a href="https://www.youtube.com/@TechnijianIT" style="color:rgb(0,109,182); text-decoration:none; font-weight:600">YouTube</a>&nbsp;<span style="color:rgb(233,236,239)">|</span>&nbsp;<a href="https://www.instagram.com/technijianinc/" style="color:rgb(0,109,182); text-decoration:none; font-weight:600">Instagram</a>&nbsp;<span style="color:rgb(233,236,239)">|</span>&nbsp;<a href="https://twitter.com/technijian_" style="color:rgb(0,109,182); text-decoration:none; font-weight:600">X</a>&nbsp;<span style="color:rgb(233,236,239)">|</span>&nbsp;<a href="https://www.tiktok.com/@technijian" style="color:rgb(0,109,182); text-decoration:none; font-weight:600">TikTok</a>&nbsp;<span style="color:rgb(233,236,239)">|</span>&nbsp;<a href="https://in.pinterest.com/technijian01/" style="color:rgb(0,109,182); text-decoration:none; font-weight:600">Pinterest</a>
</div>
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
        Subject = "Brandywine Homes - MSA Executive Summary & Cost Optimization"
        Body = @{
            ContentType = "HTML"
            Content = $htmlBody
        }
        ToRecipients = @(
            @{ EmailAddress = @{ Address = "dave@brandywine-homes.com"; Name = "Dave Barisic" } }
        )
        Attachments = @(
            @{
                "@odata.type" = "#microsoft.graph.fileAttachment"
                Name = "Brandywine-Homes-Executive-Summary-May2026.docx"
                ContentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                ContentBytes = $docBase64
            }
        )
    }
    SaveToSentItems = $true
}

Send-MgUserMail -UserId "RJain@technijian.com" -BodyParameter $params
Write-Host "Email sent to Dave Barisic <dave@brandywine-homes.com>" -ForegroundColor Green
