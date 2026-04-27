# Send NDA-VWC-001 via DocuSign (Mutual NDA between Technijian and VisionWise Capital, LLC)
# Uses canonical send-docusign.ps1 with hidden-anchor tab placement.
# Native DocuSign email (no clientUserId) -> 120-day persistent signing URL per recipient.
#
# IMPORTANT: DocuSign subscription ends April 30, 2026 (per project_docusign_ending memory).
# Today is 2026-04-27. Both parties must complete signing by April 30 or this envelope cannot be countersigned.

$ErrorActionPreference = "Stop"

$DocumentPath = "C:\vscode\tech-legal\tech-legal\clients\VWC\01_NDA\NDA-VWC-001.docx"

$EmailSubject = "Technijian and VisionWise Capital - Mutual NDA - Signature Required"

$EmailMessage = @"
Sanford,

Ahead of moving the My SEO Program proposal forward (and to keep the existing AI / CTO Advisory engagement well-documented), I am sending over a short Mutual Non-Disclosure Agreement between Technijian and VisionWise Capital.

Why we are sending this now: the SEO work involves exchange of compliance, trademark, fund, and investor-targeting materials, and the AI Lead Gen advisory has already touched investor-prospecting strategy. A standalone mutual NDA covers all of that under a single, clear confidentiality framework rather than relying on the per-engagement clauses inside each SOW. It also satisfies the carve-out in SOW-VWC-001-AI-Lead-Gen Section 2.2, which expressly contemplates a separate NDA before either party shares regulated investor information.

The NDA is mutual (protects both sides equally), runs two years, and survives for three years on confidential information. There is no commitment to a future engagement embedded in it.

Please countersign at your convenience - it should take two minutes. I will sign in parallel.

Thank you,
Ravi Jain
CEO, Technijian, Inc.
"@

powershell.exe -ExecutionPolicy Bypass -File "C:\vscode\tech-legal\tech-legal\scripts\send-docusign.ps1" `
    -DocumentPath $DocumentPath `
    -RecipientName "Sanford Coggins" `
    -RecipientEmail "sanford@visionwisecapital.com" `
    -ClientCompanyName "VisionWise Capital, LLC" `
    -SignerName "Ravi Jain" `
    -SignerEmail "rjain@technijian.com" `
    -EmailSubject $EmailSubject `
    -EmailMessage $EmailMessage
